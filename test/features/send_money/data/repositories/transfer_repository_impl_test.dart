import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/network_info/network_info.dart';
import 'package:novapay/core/sync/sync_service.dart';
import 'package:novapay/features/send_money/data/repositories/transfer_repository_impl.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_receipt.dart';
import 'package:novapay/server/models/api_response.dart';
import 'package:novapay/server/novapay_api.dart';
import 'package:novapay/utils/either_safe_runner.dart';

import '../../../../helpers/server_harness.dart';

class _MockNetworkInfo extends Mock implements NetworkInfo;

class _MockApi extends Mock implements NovaPayApi;

const _tenThousand = Money.fromKobo(1000000);

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late LocalDataStorage db;
  late NovaPayApiImpl backend;
  late _MockNetworkInfo network;
  late SyncServiceImpl sync;
  late TestClock clock;
  late TransferRepositoryImpl repository;

  void online({required bool connected}) {
    when(() => network.isConnected).thenAnswer((_) async => connected);
  }

  Future<TransferReceipt> send(Money amount) async {
    final result = await repository.queue(
      recipient: '0123456789',
      amount: amount,
    );
    return result.getOrElse(() => throw StateError('expected a receipt'));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_transfer');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('transfer_test');
    db = LocalDataStorageImpl(box);
    clock = TestClock();
    backend = buildApi(db, clock: clock);
    network = _MockNetworkInfo();
    sync = SyncServiceImpl(db, backend, network, clock);
    repository = TransferRepositoryImpl(
      backend,
      sync,
      const EitherSafeRunner(),
    );
    online(connected: true);
  });

  tearDown(() async {
    await sync.dispose();
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('available', () {
    test('starts at the opening balance', () async {
      final result = await repository.available();

      expect(result, const Right<Failure, Money>(Money.fromKobo(24800000)));
    });

    test('committed money is already gone', () async {
      online(connected: false);
      await send(_tenThousand);

      final result = await repository.available();

      expect(result, const Right<Failure, Money>(Money.fromKobo(23800000)));
    });

    test('a refused read becomes a Failure', () async {
      final api = _MockApi();
      when(api.balance).thenReturn(
        ApiResponse<int>.failure(code: 503, message: 'Wallet unavailable'),
      );
      final failing = TransferRepositoryImpl(
        api,
        sync,
        const EitherSafeRunner(),
      );

      expect(
        await failing.available(),
        const Left<Failure, Money>(Failure.serverError('Wallet unavailable')),
      );
    });
  });

  group('queue', () {
    test('online, the transfer settles and the ledger has it once', () async {
      final receipt = await send(_tenThousand);

      expect(receipt.settled, isTrue);
      expect(receipt.isPending, isFalse);
      expect(receipt.amount, _tenThousand);
      expect(backend.transactions().requireData, hasLength(1));
      expect(backend.balance().requireData, 23800000);
    });

    test('offline, it is saved and reported as pending, not failed', () async {
      online(connected: false);

      final receipt = await send(_tenThousand);

      expect(receipt.isPending, isTrue);
      expect(sync.pending(), hasLength(1));
      expect(backend.transactions().requireData, isEmpty);
      expect(backend.balance().requireData, 24800000);
    });

    test('the reference is the idempotency key that was sent', () async {
      final receipt = await send(_tenThousand);

      expect(backend.hasApplied(receipt.reference), isTrue);
      expect(sync.actions().single.id, receipt.reference);
    });

    test(
      'a transport failure leaves it queued rather than losing it',
      () async {
        backend.failNext = 1;

        final receipt = await send(_tenThousand);

        expect(receipt.isPending, isTrue);
        expect(sync.pending(), hasLength(1));
        expect(backend.transactions().requireData, isEmpty);
      },
    );

    test('over-commitment is refused at enqueue, not bounced later', () async {
      online(connected: false);
      await send(const Money.fromKobo(20000000));

      final result = await repository.queue(
        recipient: '0123456789',
        amount: const Money.fromKobo(20000000),
      );

      expect(
        result,
        const Left<Failure, TransferReceipt>(
          Failure.serverError('Not enough in your wallet for this transfer'),
        ),
      );
      expect(sync.actions(), hasLength(1));
    });

    test(
      'three offline transfers of half the balance: third refused',
      () async {
        online(connected: false);
        const half = Money.fromKobo(12400000);

        await send(half);
        await send(half);
        final third = await repository.queue(
          recipient: '0123456789',
          amount: half,
        );

        expect(third.isLeft(), isTrue);
        expect(sync.pending(), hasLength(2));
      },
    );
  });
}
