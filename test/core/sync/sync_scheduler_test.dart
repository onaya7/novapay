import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/network_info/network_info.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_scheduler.dart';
import 'package:novapay/core/sync/sync_service.dart';

import '../../helpers/server_harness.dart';

class _MockSyncService extends Mock implements SyncService;

class _MockNetworkInfo extends Mock implements NetworkInfo;

void main() {
  late _MockSyncService sync;
  late _MockNetworkInfo network;
  late StreamController<List<PendingAction>> changes;
  late StreamController<bool> connectivity;
  late TestClock clock;
  late SyncScheduler scheduler;

  PendingAction action({
    PendingActionStatus status = PendingActionStatus.queued,
    Duration? dueIn,
    String id = 'a1',
  }) => PendingAction(
    id: id,
    type: PendingActionType.send,
    amountKobo: 500000,
    payload: const {'recipient': '0123456789'},
    createdAt: clock.now(),
    status: status,
    nextAttemptAt: dueIn == null ? null : clock.now().add(dueIn),
  );

  setUp(() {
    sync = _MockSyncService();
    network = _MockNetworkInfo();
    changes = StreamController<List<PendingAction>>.broadcast();
    connectivity = StreamController<bool>.broadcast();
    clock = TestClock();
    when(() => sync.changes).thenAnswer((_) => changes.stream);
    when(() => network.onConnectivityChanged)
        .thenAnswer((_) => connectivity.stream);
    when(sync.actions).thenReturn([]);
    when(sync.recoverInterrupted).thenAnswer((_) async {});
    when(sync.drain).thenAnswer((_) async {});
    scheduler = SyncScheduler(sync, network, clock);
  });

  tearDown(() async {
    await changes.close();
    await connectivity.close();
  });

  /// Starts the scheduler inside the fake zone, which never advances on its
  /// own, so every timer below fires on an elapse rather than on wall time.
  void started(FakeAsync async) {
    unawaited(scheduler.start());
    async.flushMicrotasks();
  }

  void emit(FakeAsync async, List<PendingAction> actions) {
    changes.add(actions);
    async.flushMicrotasks();
  }

  void stopped(FakeAsync async) {
    unawaited(scheduler.dispose());
    async.elapse(Duration.zero);
  }

  test('recovers interrupted sends, then drains once', () async {
    await scheduler.start();
    await Future<void>.delayed(Duration.zero);

    verifyInOrder([sync.recoverInterrupted, sync.drain]);
    await scheduler.dispose();
  });

  test('drains when the network returns', () async {
    await scheduler.start();
    connectivity.add(true);
    await Future<void>.delayed(Duration.zero);

    verify(sync.drain).called(2);
    await scheduler.dispose();
  });

  test('a disconnection does not drain', () async {
    await scheduler.start();
    connectivity.add(false);
    await Future<void>.delayed(Duration.zero);

    verify(sync.drain).called(1);
    await scheduler.dispose();
  });

  test('each reconnection drains, none coalesced away', () async {
    await scheduler.start();
    connectivity
      ..add(true)
      ..add(true);
    await Future<void>.delayed(Duration.zero);

    verify(sync.drain).called(3);
    await scheduler.dispose();
  });

  test('starting twice subscribes once', () async {
    await scheduler.start();
    await scheduler.start();
    connectivity.add(true);
    await Future<void>.delayed(Duration.zero);

    verify(sync.recoverInterrupted).called(1);
    verify(sync.drain).called(2);
    await scheduler.dispose();
  });

  test('a drain that throws leaves the scheduler alive', () async {
    when(sync.drain).thenThrow(Exception('offline'));
    await scheduler.start();
    await Future<void>.delayed(Duration.zero);

    when(sync.drain).thenAnswer((_) async {});
    connectivity.add(true);
    await Future<void>.delayed(Duration.zero);

    verify(sync.drain).called(2);
    await scheduler.dispose();
  });

  test('retries a backed-off action when its window expires', () {
    fakeAsync((async) {
      started(async);
      emit(async, [action(dueIn: const Duration(seconds: 4))]);

      verify(sync.drain).called(1);

      async.elapse(const Duration(seconds: 4));

      verify(sync.drain).called(1);
      stopped(async);
    });
  });

  test('waits on the earliest window when the later comes first', () {
    fakeAsync((async) {
      started(async);
      emit(async, [
        action(id: 'later', dueIn: const Duration(seconds: 8)),
        action(id: 'sooner', dueIn: const Duration(seconds: 3)),
      ]);
      async.elapse(const Duration(seconds: 3));

      verify(sync.drain).called(2);
      stopped(async);
    });
  });

  test('waits on the earliest window when the sooner comes first', () {
    fakeAsync((async) {
      started(async);
      emit(async, [
        action(id: 'sooner', dueIn: const Duration(seconds: 3)),
        action(id: 'later', dueIn: const Duration(seconds: 8)),
      ]);
      async.elapse(const Duration(seconds: 3));

      verify(sync.drain).called(2);
      stopped(async);
    });
  });

  test('a settled queue arms no timer', () {
    fakeAsync((async) {
      started(async);
      emit(async, [
        action(
          status: PendingActionStatus.done,
          dueIn: const Duration(days: 1),
        ),
      ]);
      async.elapse(const Duration(days: 2));

      verify(sync.drain).called(1);
      stopped(async);
    });
  });

  test('an already-due action arms no timer', () {
    fakeAsync((async) {
      started(async);
      emit(async, [action(dueIn: const Duration(seconds: -5))]);
      async.elapse(const Duration(days: 1));

      verify(sync.drain).called(1);
      stopped(async);
    });
  });

  test('a queued action with no window arms no timer', () {
    fakeAsync((async) {
      started(async);
      emit(async, [action()]);
      async.elapse(const Duration(days: 1));

      verify(sync.drain).called(1);
      stopped(async);
    });
  });

  test('a window found at cold start arms the timer', () {
    fakeAsync((async) {
      when(sync.actions)
          .thenReturn([action(dueIn: const Duration(seconds: 6))]);
      started(async);
      async.elapse(const Duration(seconds: 6));

      verify(sync.drain).called(2);
      stopped(async);
    });
  });

  test('a re-arm cancels the previous timer', () {
    fakeAsync((async) {
      started(async);
      emit(async, [action(id: 'far', dueIn: const Duration(seconds: 10))]);
      emit(async, [action(id: 'near', dueIn: const Duration(seconds: 2))]);
      async.elapse(const Duration(seconds: 2));

      verify(sync.drain).called(2);

      async.elapse(const Duration(seconds: 10));

      verifyNever(sync.drain);
      stopped(async);
    });
  });

  test('dispose stops both subscriptions', () async {
    await scheduler.start();
    await Future<void>.delayed(Duration.zero);
    await scheduler.dispose();

    connectivity.add(true);
    changes.add([action(dueIn: const Duration(seconds: 1))]);
    await Future<void>.delayed(Duration.zero);

    verify(sync.drain).called(1);
  });

  test('dispose cancels an armed retry timer', () {
    fakeAsync((async) {
      started(async);
      emit(async, [action(dueIn: const Duration(seconds: 5))]);
      unawaited(scheduler.dispose());
      async.elapse(const Duration(days: 1));

      verify(sync.drain).called(1);
    });
  });

  test('dispose before start is a no-op', () async {
    await scheduler.dispose();

    verifyNever(sync.drain);
  });
}
