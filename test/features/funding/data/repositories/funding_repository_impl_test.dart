import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/network_info/network_info.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_service.dart';
import 'package:novapay/features/funding/data/repositories/funding_repository_impl.dart';
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
  late TestClock clock;
  late FundingRepositoryImpl repository;

  void online({required bool connected}) {
    when(() => network.isConnected).thenAnswer((_) async => connected);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_funding_repo');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('funding_repo_test');
    db = LocalDataStorageImpl(box);
    clock = TestClock();
    backend = buildApi(db, clock: clock);
    network = _MockNetworkInfo();
    sync = SyncServiceImpl(db, backend, network, clock);
    repository = FundingRepositoryImpl(backend, sync, const EitherSafeRunner());
    online(connected: true);
  });

  tearDown(() async {
    await sync.dispose();
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('balance', () {
    test('reads the wallet balance in kobo', () async {
      final result = await repository.balance();

      expect(result, const Right<Failure, Money>(Money.fromKobo(24800000)));
    });

    test('a refused read becomes a Failure', () async {
      final api = _MockApi();
      when(api.balance).thenReturn(
        ApiResponse<int>.failure(code: 503, message: 'Wallet unavailable'),
      );
      final failing = FundingRepositoryImpl(
        api,
        sync,
        const EitherSafeRunner(),
      );

      final result = await failing.balance();

      expect(
        result,
        const Left<Failure, Money>(Failure.serverError('Wallet unavailable')),
      );
    });
  });

  group('addMoney', () {
    test('is queued rather than sent, so it survives being offline', () async {
      online(connected: false);

      final result = await repository.addMoney(const Money.fromKobo(500000));

      expect(result.isRight(), isTrue);
      expect(sync.pending(), hasLength(1));
      expect(sync.pending().single.type, PendingActionType.fund);
      expect(backend.balance().requireData, 24800000);
    });

    test('a zero amount is refused before it is queued', () async {
      final result = await repository.addMoney(Money.zero);

      expect(
        result,
        const Left<Failure, Unit>(
          Failure.serverError('Enter an amount greater than zero'),
        ),
      );
      expect(sync.actions(), isEmpty);
    });

    test('does not reduce what may be spent while it is queued', () async {
      online(connected: false);
      await repository.addMoney(const Money.fromKobo(500000));

      expect(sync.pendingKobo(), 0);
    });
  });
}
