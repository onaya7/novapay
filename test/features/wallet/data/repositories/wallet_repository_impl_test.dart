import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/core/network_info/network_info.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_service.dart';
import 'package:novapay/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/server/models/api_response.dart';
import 'package:novapay/server/novapay_api.dart';
import 'package:novapay/utils/either_safe_runner.dart';

import '../../../../helpers/server_harness.dart';

class _MockNetworkInfo extends Mock implements NetworkInfo;

class _MockApi extends Mock implements NovaPayApi;

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late LocalDataStorage db;
  late NovaPayApiImpl backend;
  late _MockNetworkInfo network;
  late SyncServiceImpl sync;
  late WalletRepositoryImpl repository;

  void online({required bool connected}) {
    when(() => network.isConnected).thenAnswer((_) async => connected);
  }

  Future<WalletSnapshot> loaded() async {
    final result = await repository.load();
    return result.getOrElse(() => throw StateError('expected a snapshot'));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_wallet_repo');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('wallet_repo_test');
    db = LocalDataStorageImpl(box);
    backend = buildApi(db);
    network = _MockNetworkInfo();
    sync = SyncServiceImpl(db, backend, network);
    repository = WalletRepositoryImpl(backend, sync, const EitherSafeRunner());
    online(connected: false);
  });

  tearDown(() async {
    await sync.dispose();
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('load', () {
    test('a fresh wallet is the opening balance and nothing else', () async {
      final snapshot = await loaded();

      expect(snapshot.confirmedKobo, 24800000);
      expect(snapshot.pendingKobo, 0);
      expect(snapshot.activity, isEmpty);
      expect(snapshot.hasPending, isFalse);
    });

    test('a queued send appears as pending and reduces available', () async {
      await sync.enqueue(
        type: PendingActionType.send,
        amountKobo: 500000,
        payload: const {'recipient': '0123456789'},
      );

      final snapshot = await loaded();

      expect(snapshot.pendingKobo, 500000);
      expect(snapshot.available.format(), '₦243,000.00');
      expect(snapshot.activity, hasLength(1));
      expect(snapshot.activity.single.status, ActivityStatus.pending);
      expect(snapshot.activity.single.title, 'To 0123456789');
    });

    test('a queued action is money leaving, so it renders negative', () async {
      await sync.enqueue(
        type: PendingActionType.send,
        amountKobo: 500000,
        payload: const {'recipient': '0123456789'},
      );

      final snapshot = await loaded();

      expect(snapshot.activity.single.amountKobo, -500000);
      expect(snapshot.activity.single.isDebit, isTrue);
    });

    test('a contribution is titled without needing a recipient', () async {
      final goal = await backend.createGoal(
        id: 'g1',
        name: 'Rent',
        targetKobo: 10000000,
        targetDate: DateTime(2026, 12),
      );
      await sync.enqueue(
        type: PendingActionType.contribute,
        amountKobo: 100000,
        payload: {'goalId': goal.requireData.id},
      );

      final snapshot = await loaded();

      expect(snapshot.activity.single.title, 'Savings contribution');
    });

    test('a send with no recipient in the payload still reads', () async {
      await sync.enqueue(
        type: PendingActionType.send,
        amountKobo: 100,
        payload: const {},
      );

      final snapshot = await loaded();

      expect(snapshot.activity.single.title, 'To a NovaPay account');
    });

    test('a settled action is not listed twice', () async {
      online(connected: true);
      await sync.enqueue(
        type: PendingActionType.send,
        amountKobo: 500000,
        payload: const {'recipient': '0123456789'},
      );
      await sync.drain();

      final snapshot = await loaded();

      expect(sync.actions().single.status, PendingActionStatus.done);
      expect(snapshot.activity, hasLength(1));
      expect(snapshot.activity.single.status, ActivityStatus.settled);
      expect(snapshot.pendingKobo, 0);
    });

    test('an exhausted action is shown as failed, not hidden', () async {
      online(connected: true);
      backend.failNext = 10;
      await sync.enqueue(
        type: PendingActionType.send,
        amountKobo: 500000,
        payload: const {'recipient': '0123456789'},
      );
      for (var i = 0; i < 5; i++) {
        await sync.drain();
      }

      final snapshot = await loaded();

      expect(snapshot.activity.single.status, ActivityStatus.failed);
    });

    test('newest first, whichever side of the queue it came from', () async {
      online(connected: true);
      await sync.enqueue(
        type: PendingActionType.send,
        amountKobo: 100000,
        payload: const {'recipient': '0000000001'},
      );
      await sync.drain();
      online(connected: false);
      await sync.enqueue(
        type: PendingActionType.send,
        amountKobo: 200000,
        payload: const {'recipient': '0000000002'},
      );

      final snapshot = await loaded();
      final occurred = snapshot.activity.map((a) => a.occurredAt).toList();

      expect(snapshot.activity, hasLength(2));
      expect(occurred.first.isAfter(occurred.last), isTrue);
      expect(snapshot.activity.first.status, ActivityStatus.pending);
    });

    test('a refused read becomes a Failure, not a crash', () async {
      final api = _MockApi();
      when(api.balance).thenReturn(
        ApiResponse<int>.failure(code: 503, message: 'Wallet unavailable'),
      );
      final failing = WalletRepositoryImpl(api, sync, const EitherSafeRunner());

      final result = await failing.load();

      expect(
        result,
        const Left<Failure, WalletSnapshot>(
          Failure.serverError('Wallet unavailable'),
        ),
      );
    });
  });

  group('watch', () {
    test('re-emits with the new pending total when the queue moves', () async {
      final snapshots = <WalletSnapshot>[];
      final subscription = repository.watch().listen(snapshots.add);

      await sync.enqueue(
        type: PendingActionType.send,
        amountKobo: 500000,
        payload: const {'recipient': '0123456789'},
      );
      await Future<void>.delayed(Duration.zero);

      expect(snapshots, isNotEmpty);
      expect(snapshots.last.pendingKobo, 500000);
      expect(snapshots.last.activity.single.status, ActivityStatus.pending);

      await subscription.cancel();
    });
  });
}
