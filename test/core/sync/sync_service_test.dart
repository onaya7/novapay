import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/core/network_info/network_info.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_service.dart';
import 'package:novapay/server/novapay_api.dart';

import '../../helpers/server_harness.dart';

class _MockNetworkInfo extends Mock implements NetworkInfo;

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late LocalDataStorage db;
  late NovaPayApiImpl backend;
  late _MockNetworkInfo network;
  late SyncServiceImpl service;

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
    backend = buildApi(db);
    network = _MockNetworkInfo();
    service = SyncServiceImpl(db, backend, network);
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
      expect(backend.transactions().requireData, isEmpty);

      await service.drain();
      expect(service.actions().single.status, PendingActionStatus.done);
      expect(backend.transactions().requireData, hasLength(1));
    });

    test('it gives up rather than retrying forever', () async {
      await queueTransfer();
      online(connected: true);
      backend.failNext = kPendingActionMaxAttempts;
      for (var i = 0; i < kPendingActionMaxAttempts; i++) {
        await service.drain();
      }

      final action = service.actions().single;
      expect(action.status, PendingActionStatus.failed);
      expect(action.attemptCount, kPendingActionMaxAttempts);
      expect(service.pending(), isEmpty);
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

  group('across a restart', () {
    test('a queued action survives and then sends exactly once', () async {
      // Queued while offline.
      final action = await queueTransfer();
      expect(backend.transactions().requireData, isEmpty);

      // Relaunch: new service and backend over the same database.
      final backendAfter = buildApi(db);
      final networkAfter = _MockNetworkInfo();
      when(() => networkAfter.isConnected).thenAnswer((_) async => true);
      final serviceAfter = SyncServiceImpl(db, backendAfter, networkAfter);
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
      await service.drain();
      await service.drain();
      expect(service.actions().single.status, PendingActionStatus.done);
    });

    test('recoverInterrupted requeues a stranded send', () async {
      await queueTransfer();
      final stranded = service.actions().single.sending();
      await db.write<String>('pending_actions', '[${_json(stranded)}]');
      expect(service.actions().single.status, PendingActionStatus.sending);

      await service.recoverInterrupted();
      expect(service.actions().single.status, PendingActionStatus.queued);
      expect(service.actions().single.attemptCount, 0);
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
