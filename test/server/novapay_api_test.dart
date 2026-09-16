import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/server/api_exception.dart';
import 'package:novapay/server/models/api_response.dart';
import 'package:novapay/server/models/transaction.dart';
import 'package:novapay/server/novapay_api.dart';

import '../helpers/server_harness.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late LocalDataStorage db;
  late NovaPayApiImpl api;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_api');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('api_test');
    db = LocalDataStorageImpl(box);
    api = buildApi(db);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<ApiResponse<Transaction>> send({
    String key = 'k1',
    int amountKobo = 500000,
  }) => api.transfer(
    idempotencyKey: key,
    recipient: '0123456789',
    amountKobo: amountKobo,
  );

  int balance() => api.balance().requireData;

  group('the envelope', () {
    test('every read answers 200 with data', () {
      expect(api.balance().status, ApiStatus.success);
      expect(api.balance().code, 200);
      expect(api.balance().message, 'OK');
      expect(balance(), 24800000);
      expect(Money.fromKobo(balance()).format(), '₦248,000.00');
      expect(api.transactions().requireData, isEmpty);
      expect(api.goals().requireData, isEmpty);
    });

    test('a write answers 201 with the thing it created', () async {
      final response = await send();
      expect(response.isSuccess, isTrue);
      expect(response.code, 201);
      expect(response.requireData.amountKobo, -500000);
      expect(response.requireData.id, 'k1');
    });

    test('reading data off an error fails loudly', () {
      final failed = api.goal('missing');
      expect(failed.isError, isTrue);
      expect(() => failed.requireData, throwsStateError);
    });
  });

  group('refusals are responses, not exceptions', () {
    test('not enough money answers 402', () async {
      final response = await send(amountKobo: 99900000);
      expect(response.isError, isTrue);
      expect(response.code, 402);
      expect(response.message, 'Not enough in your wallet');
      expect(balance(), 24800000);
    });

    test('an invalid amount answers 422', () async {
      final response = await send(amountKobo: 0);
      expect(response.code, 422);
      expect(balance(), 24800000);
    });

    test('an unknown goal answers 404', () async {
      final response = await api.contribute(
        idempotencyKey: 'c1',
        goalId: 'nope',
        amountKobo: 1000,
      );
      expect(response.code, 404);
    });

    test('a missing goal read answers 404', () {
      expect(api.goal('missing').code, 404);
    });
  });

  group('idempotency', () {
    test('the same key applied three times moves money once', () async {
      await send();
      await send();
      await send();
      expect(balance(), 24300000);
      expect(api.transactions().requireData, hasLength(1));
    });

    test('a replay answers with the original transaction', () async {
      final first = await send();
      final replay = await send();
      expect(replay.isSuccess, isTrue);
      expect(replay.requireData.id, first.requireData.id);
      expect(replay.requireData.occurredAt, first.requireData.occurredAt);
    });

    test('a restart still recognises a key it already applied', () async {
      await send();

      // A fresh server over the same storage is what a relaunch looks like.
      final afterRestart = buildApi(db);
      expect(afterRestart.balance().requireData, 24300000);
      expect(afterRestart.hasApplied('k1'), isTrue);

      await afterRestart.transfer(
        idempotencyKey: 'k1',
        recipient: '0123456789',
        amountKobo: 500000,
      );
      expect(afterRestart.balance().requireData, 24300000);
      expect(afterRestart.transactions().requireData, hasLength(1));
    });
  });

  group('transport', () {
    test('a transport failure throws, unlike a refusal', () async {
      api.failNext = 1;
      await expectLater(send(), throwsA(isA<ApiException>()));
      expect(balance(), 24800000);
      expect(api.hasApplied('k1'), isFalse);

      // failNext is spent, not sticky.
      final next = await send();
      expect(next.isSuccess, isTrue);
      expect(balance(), 24300000);
    });

    test('latency delays a write without changing the result', () async {
      final slow = buildApi(db, latency: const Duration(milliseconds: 20));
      final started = DateTime.now();
      final response = await slow.transfer(
        idempotencyKey: 'slow',
        recipient: '0123456789',
        amountKobo: 100,
      );
      expect(DateTime.now().difference(started).inMilliseconds, greaterThan(9));
      expect(response.isSuccess, isTrue);
      expect(slow.balance().requireData, 24799900);
    });
  });

  group('goals', () {
    test('a goal is created, then contributed to', () async {
      final created = await api.createGoal(
        id: 'g1',
        name: 'Rent',
        targetKobo: 10000000,
        targetDate: DateTime.utc(2027),
      );
      expect(created.code, 201);
      expect(created.requireData.savedKobo, 0);
      expect(api.goals().requireData, hasLength(1));

      final funded = await api.contribute(
        idempotencyKey: 'c1',
        goalId: 'g1',
        amountKobo: 2500000,
      );
      expect(funded.code, 200);
      expect(funded.requireData.savedKobo, 2500000);
      expect(funded.requireData.percentComplete, 25);
      expect(balance(), 22300000);
    });

    test('a replayed contribution answers with the goal unchanged', () async {
      await api.createGoal(
        id: 'g1',
        name: 'Rent',
        targetKobo: 10000000,
        targetDate: DateTime.utc(2027),
      );
      await api.contribute(
        idempotencyKey: 'c1',
        goalId: 'g1',
        amountKobo: 2500000,
      );
      final replay = await api.contribute(
        idempotencyKey: 'c1',
        goalId: 'g1',
        amountKobo: 2500000,
      );
      expect(replay.requireData.savedKobo, 2500000);
      expect(balance(), 22300000);
    });

    test('a goal can be read back by id', () async {
      await api.createGoal(
        id: 'g1',
        name: 'Rent',
        targetKobo: 10000000,
        targetDate: DateTime.utc(2027),
      );
      expect(api.goal('g1').requireData.name, 'Rent');
    });
  });

  test('reset wipes the server, applied keys included', () async {
    await send();
    await api.createGoal(
      id: 'g1',
      name: 'Rent',
      targetKobo: 10000000,
      targetDate: DateTime.utc(2027),
    );

    await api.reset();

    expect(balance(), 24800000);
    expect(api.transactions().requireData, isEmpty);
    expect(api.goals().requireData, isEmpty);
    expect(api.hasApplied('k1'), isFalse);
  });
}
