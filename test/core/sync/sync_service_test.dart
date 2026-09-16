import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/core/network_info/network_info.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_service.dart';
import 'package:novapay/server/models/api_response.dart';
import 'package:novapay/server/models/savings_goal.dart';
import 'package:novapay/server/models/transaction.dart';
import 'package:novapay/server/novapay_api.dart';

import '../../helpers/server_harness.dart';

class _MockNetworkInfo extends Mock implements NetworkInfo;

/// Holds every transfer open until the test releases it, so two drains can be
/// put in flight at once on purpose. A `Future.delayed` here would let the
/// first drain finish before the second started, and the test would pass
/// whether or not the mutex worked.
class _GatedApi implements NovaPayApi {
  _GatedApi(this._inner);

  final NovaPayApi _inner;
  final Completer<void> gate = Completer<void>();
  int transferCalls = 0;

  @override
  Future<ApiResponse<Transaction>> transfer({
    required String idempotencyKey,
    required String recipient,
    required int amountKobo,
  }) async {
    transferCalls++;
    await gate.future;
    return await _inner.transfer(
      idempotencyKey: idempotencyKey,
      recipient: recipient,
      amountKobo: amountKobo,
    );
  }

  @override
  Future<ApiResponse<Transaction>> fund({
    required String idempotencyKey,
    required int amountKobo,
  }) => _inner.fund(idempotencyKey: idempotencyKey, amountKobo: amountKobo);

  @override
  ApiResponse<int> balance() => _inner.balance();

  @override
  ApiResponse<List<Transaction>> transactions() => _inner.transactions();

  @override
  ApiResponse<List<SavingsGoal>> goals() => _inner.goals();

  @override
  ApiResponse<SavingsGoal> goal(String id) => _inner.goal(id);

  @override
  Future<ApiResponse<SavingsGoal>> contribute({
    required String idempotencyKey,
    required String goalId,
    required int amountKobo,
  }) => _inner.contribute(
    idempotencyKey: idempotencyKey,
    goalId: goalId,
    amountKobo: amountKobo,
  );

  @override
  Future<ApiResponse<SavingsGoal>> createGoal({
    required String id,
    required String name,
    required int targetKobo,
    required DateTime targetDate,
  }) => _inner.createGoal(
    id: id,
    name: name,
    targetKobo: targetKobo,
    targetDate: targetDate,
  );
}

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late LocalDataStorage db;
  late NovaPayApiImpl backend;
  late _MockNetworkInfo network;
  late SyncServiceImpl service;
  late TestClock clock;

  void online({required bool connected}) {
    when(() => network.isConnected).thenAnswer((_) async => connected);
  }

  Future<PendingAction> queueTransfer({int amountKobo = 500000}) =>
      service.enqueue(
        type: PendingActionType.send,
        amountKobo: amountKobo,
        payload: const {'recipient': '0123456789'},
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_sync');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('sync_test');
    db = LocalDataStorageImpl(box);
    clock = TestClock();
    backend = buildApi(db, clock: clock);
    network = _MockNetworkInfo();
    service = SyncServiceImpl(db, backend, network, clock);
    online(connected: false);
  });

  tearDown(() async {
    await service.dispose();
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('offline', () {
    test('the action is saved and stays pending', () async {
      final action = await queueTransfer();
      expect(action.status, PendingActionStatus.queued);
      expect(service.pending(), hasLength(1));
      expect(backend.transactions().requireData, isEmpty);
      expect(backend.balance().requireData, 24800000);
    });

    test('the wallet can show what is still owed', () async {
      await queueTransfer();
      await queueTransfer(amountKobo: 250000);
      expect(service.pendingKobo(), 750000);
    });

    test('several actions queue in the order they were made', () async {
      await queueTransfer(amountKobo: 100);
      await queueTransfer(amountKobo: 200);
      await queueTransfer(amountKobo: 300);
      expect(service.pending().map((a) => a.amountKobo).toList(), <int>[
        100,
        200,
        300,
      ]);
    });
  });

  group('back online', () {
    test('a queued action is sent and settles', () async {
      await queueTransfer();
      online(connected: true);
      await service.drain();

      expect(service.pending(), isEmpty);
      expect(service.actions().single.status, PendingActionStatus.done);
      expect(backend.transactions().requireData, hasLength(1));
      expect(backend.balance().requireData, 24300000);
    });

    test('draining twice does not send twice', () async {
      await queueTransfer();
      online(connected: true);
      await service.drain();
      await service.drain();
      await service.drain();

      expect(backend.transactions().requireData, hasLength(1));
      expect(backend.balance().requireData, 24300000);
    });

    test('a failure requeues it for another go', () async {
      await queueTransfer();
      // enqueue kicks off a drain of its own; let it settle while still
      // offline so it cannot consume the injected failure below.
      await service.drain();

      online(connected: true);
      backend.failNext = 1;
      await service.drain();

      final action = service.actions().single;
      expect(action.status, PendingActionStatus.queued);
      expect(action.attemptCount, 1);
      expect(action.sawAmbiguousAttempt, isTrue);
      expect(backend.transactions().requireData, isEmpty);

      // It is behind a backoff window, so an immediate drain is a no-op.
      await service.drain();
      expect(service.actions().single.attemptCount, 1);

      clock.advance(const Duration(minutes: 31));
      await service.drain();
      expect(service.actions().single.status, PendingActionStatus.done);
      expect(backend.transactions().requireData, hasLength(1));
    });

    test('an exhausted budget is handed over, not retried forever', () async {
      await queueTransfer();
      online(connected: true);
      backend.failNext = kPendingActionMaxAttempts + 1;
      for (var i = 0; i < kPendingActionMaxAttempts; i++) {
        clock.advance(const Duration(minutes: 31));
        await service.drain();
      }

      final action = service.actions().single;
      expect(action.status, PendingActionStatus.unresolved);
      expect(action.attemptCount, kPendingActionMaxAttempts);
      expect(service.pending(), isEmpty);
      expect(service.unresolved(), hasLength(1));
    });

    test('an unknown outcome keeps holding the money', () async {
      await queueTransfer();
      online(connected: true);
      backend.failNext = kPendingActionMaxAttempts + 1;
      for (var i = 0; i < kPendingActionMaxAttempts; i++) {
        clock.advance(const Duration(minutes: 31));
        await service.drain();
      }

      // Never released: the transfer may already have moved the money.
      expect(service.actions().single.status, PendingActionStatus.unresolved);
      expect(service.pendingKobo(), 500000);
    });

    test('a refusal is terminal at once and releases the hold', () async {
      online(connected: true);
      // More than the wallet holds, so the server answers rather than throws.
      await service.enqueue(
        type: PendingActionType.send,
        amountKobo: 99900000,
        payload: const {'recipient': '0123456789'},
      );

      final action = service.actions().single;
      expect(action.status, PendingActionStatus.rejected);
      expect(action.attemptCount, 1);
      expect(action.failureMessage, contains('Not enough'));
      expect(action.sawAmbiguousAttempt, isFalse);
      // Provably not processed, so the money is spendable again.
      expect(service.pendingKobo(), 0);
    });

    test('a refusal is never retried, however many drains happen', () async {
      online(connected: true);
      await service.enqueue(
        type: PendingActionType.send,
        amountKobo: 99900000,
        payload: const {'recipient': '0123456789'},
      );

      for (var i = 0; i < 5; i++) {
        clock.advance(const Duration(hours: 1));
        await service.drain();
      }

      expect(service.actions().single.attemptCount, 1);
    });

    test('one action inside its window does not block another', () async {
      online(connected: true);
      backend.failNext = 1;
      final blocked = await queueTransfer();
      expect(service.actions().single.status, PendingActionStatus.queued);

      final second = await queueTransfer(amountKobo: 100000);

      final byId = {for (final a in service.actions()) a.id: a};
      expect(byId[blocked.id]!.status, PendingActionStatus.queued);
      expect(byId[second.id]!.status, PendingActionStatus.done);
    });
  });

  group('contributions', () {
    test('a queued contribution lands in the goal', () async {
      await backend.createGoal(
        id: 'g1',
        name: 'Rent',
        targetKobo: 10000000,
        targetDate: DateTime.utc(2027),
      );

      await service.enqueue(
        type: PendingActionType.contribute,
        amountKobo: 250000,
        payload: const {'goalId': 'g1'},
      );
      expect(backend.goals().requireData.first.savedKobo, 0);

      online(connected: true);
      await service.drain();

      expect(backend.goals().requireData.first.savedKobo, 250000);
      expect(backend.balance().requireData, 24550000);
      expect(service.actions().single.status, PendingActionStatus.done);
    });

    test('replaying a contribution adds it once', () async {
      await backend.createGoal(
        id: 'g1',
        name: 'Rent',
        targetKobo: 10000000,
        targetDate: DateTime.utc(2027),
      );
      await service.enqueue(
        type: PendingActionType.contribute,
        amountKobo: 250000,
        payload: const {'goalId': 'g1'},
      );

      online(connected: true);
      await service.drain();
      await service.drain();

      expect(backend.goals().requireData.first.savedKobo, 250000);
    });
  });

  group('funding', () {
    test('a queued top-up credits the wallet', () async {
      await service.enqueue(
        type: PendingActionType.fund,
        amountKobo: 500000,
        payload: const {},
      );
      expect(backend.balance().requireData, 24800000);

      online(connected: true);
      await service.drain();

      expect(backend.balance().requireData, 25300000);
      expect(service.actions().single.status, PendingActionStatus.done);
    });
  });

  group('two triggers at once', () {
    test('connectivity-regained and resume together send once', () async {
      // Queued offline, so enqueue's own drain cannot consume it first.
      final action = await queueTransfer();
      online(connected: true);

      final gated = _GatedApi(backend);
      final racing = SyncServiceImpl(db, gated, network, clock);
      addTearDown(racing.dispose);

      // Both in the same microtask, which is exactly what connectivity and
      // app-resume do when a phone comes back.
      final first = racing.drain();
      final second = racing.drain();
      gated.gate.complete();
      await Future.wait([first, second]);

      // This is the assertion that tests the mutex. The ledger check below
      // would pass even with a broken guard, because both drains would carry
      // the same idempotency key and the server would collapse the second.
      expect(gated.transferCalls, 1);

      expect(backend.transactions().requireData, hasLength(1));
      expect(backend.balance().requireData, 24300000);
      expect(racing.actions().single.id, action.id);
      expect(racing.actions().single.status, PendingActionStatus.done);
    });
  });

  group('across a restart', () {
    test('a queued action survives and then sends exactly once', () async {
      // Queued while offline.
      final action = await queueTransfer();
      expect(backend.transactions().requireData, isEmpty);

      // Relaunch: new service and backend over the same database.
      final backendAfter = buildApi(db, clock: clock);
      final networkAfter = _MockNetworkInfo();
      when(() => networkAfter.isConnected).thenAnswer((_) async => true);
      final serviceAfter = SyncServiceImpl(
        db,
        backendAfter,
        networkAfter,
        clock,
      );
      addTearDown(serviceAfter.dispose);

      expect(serviceAfter.pending().single.id, action.id);

      await serviceAfter.recoverInterrupted();
      await serviceAfter.drain();
      await serviceAfter.drain();

      expect(backendAfter.transactions().requireData, hasLength(1));
      expect(backendAfter.balance().requireData, 24300000);
      expect(serviceAfter.actions().single.status, PendingActionStatus.done);
    });

    test('a send interrupted mid-flight is retried, not lost', () async {
      // Killing the app during a send leaves the row marked sending.
      online(connected: true);
      backend.failNext = 1;
      await queueTransfer();
      clock.advance(const Duration(minutes: 31));
      await service.drain();
      expect(service.actions().single.status, PendingActionStatus.done);
    });

    test('recoverInterrupted requeues a stranded send', () async {
      await queueTransfer();
      final stranded = service.actions().single.sending('attempt-1');
      await db.write<String>('pending_actions', '[${_json(stranded)}]');
      expect(service.actions().single.status, PendingActionStatus.sending);

      await service.recoverInterrupted();
      final recovered = service.actions().single;
      expect(recovered.status, PendingActionStatus.queued);
      // It reached the server once, so the outcome is unknown from here on.
      expect(recovered.sawAmbiguousAttempt, isTrue);
    });
  });

  group('housekeeping', () {
    test('a row this build cannot read is skipped, not fatal', () async {
      await db.write<String>('pending_actions', '[{"schemaVersion":99}]');
      expect(service.actions(), isEmpty);
      expect(service.pending(), isEmpty);
    });

    test('settled actions can be cleared away', () async {
      await queueTransfer();
      online(connected: true);
      await service.drain();
      expect(service.actions(), hasLength(1));

      await service.clearFinished();
      expect(service.actions(), isEmpty);
    });

    test('changes are published for the UI', () async {
      final seen = <int>[];
      final sub = service.changes.listen((actions) => seen.add(actions.length));
      await queueTransfer();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen, isNotEmpty);
    });

    test('an empty queue reports nothing owed', () {
      expect(service.pending(), isEmpty);
      expect(service.pendingKobo(), 0);
      expect(service.actions(), isEmpty);
    });
  });
}

String _json(PendingAction action) {
  final json = action.toJson();
  final payload = json['payload'] as Map<String, dynamic>;
  return '{"schemaVersion":${json['schemaVersion']},"id":"${json['id']}",'
      '"type":"${json['type']}","amountKobo":${json['amountKobo']},'
      '"payload":{"recipient":"${payload['recipient']}"},'
      '"createdAt":"${json['createdAt']}","status":"${json['status']}",'
      '"attemptCount":${json['attemptCount']}}';
}
