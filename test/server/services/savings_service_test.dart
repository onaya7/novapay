import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/server/api_exception.dart';
import 'package:novapay/server/models/savings_goal.dart';
import 'package:novapay/server/repositories/account_repository.dart';
import 'package:novapay/server/repositories/idempotency_repository.dart';
import 'package:novapay/server/repositories/savings_goal_repository.dart';
import 'package:novapay/server/repositories/transaction_repository.dart';
import 'package:novapay/server/services/savings_service.dart';

import '../../helpers/server_harness.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late AccountRepository accounts;
  late TransactionRepository transactions;
  late SavingsGoalRepository goals;
  late IdempotencyRepository idempotency;
  late SavingsService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_savings');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('savings_test');
    final db = LocalDataStorageImpl(box);
    accounts = AccountRepositoryImpl(db);
    transactions = TransactionRepositoryImpl(db);
    goals = SavingsGoalRepositoryImpl(db);
    idempotency = IdempotencyRepositoryImpl(db);
    service = SavingsServiceImpl(
      goals,
      accounts,
      transactions,
      idempotency,
      TestClock(),
    );
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<SavingsGoal> createRent() => service.createGoal(
    id: 'g1',
    name: 'Rent',
    targetKobo: 10000000,
    targetDate: DateTime.utc(2027),
  );

  group('createGoal', () {
    test('stores a goal that starts empty', () async {
      final goal = await createRent();
      expect(goal.name, 'Rent');
      expect(goal.savedKobo, 0);
      expect(goals.findAll(), hasLength(1));
      expect(goals.findById('g1'), isNotNull);
    });

    test('trims the name', () async {
      final goal = await service.createGoal(
        id: 'g2',
        name: '  School fees  ',
        targetKobo: 5000000,
        targetDate: DateTime.utc(2027),
      );
      expect(goal.name, 'School fees');
    });

    test('refuses an empty name or a non-positive target', () async {
      await expectLater(
        service.createGoal(
          id: 'g3',
          name: '   ',
          targetKobo: 100,
          targetDate: DateTime.utc(2027),
        ),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        service.createGoal(
          id: 'g4',
          name: 'Car',
          targetKobo: 0,
          targetDate: DateTime.utc(2027),
        ),
        throwsA(isA<ApiException>()),
      );
      expect(goals.findAll(), isEmpty);
    });

    test('an unknown id finds nothing', () {
      expect(goals.findById('missing'), isNull);
    });
  });

  group('contribute', () {
    setUp(createRent);

    test('moves money from the wallet into the goal', () async {
      await service.contribute(
        idempotencyKey: 'c1',
        goalId: 'g1',
        amountKobo: 250000,
      );
      expect(goals.findById('g1')!.savedKobo, 250000);
      expect(accounts.balanceKobo(), 24550000);
      expect(transactions.findAll(), hasLength(1));
      expect(transactions.findAll().single.title, 'Saved to Rent');
    });

    test('the same key applied three times adds once', () async {
      for (var i = 0; i < 3; i++) {
        await service.contribute(
          idempotencyKey: 'c1',
          goalId: 'g1',
          amountKobo: 250000,
        );
      }
      expect(goals.findById('g1')!.savedKobo, 250000);
      expect(accounts.balanceKobo(), 24550000);
    });

    test('successive contributions accumulate', () async {
      await service.contribute(
        idempotencyKey: 'c1',
        goalId: 'g1',
        amountKobo: 250000,
      );
      await service.contribute(
        idempotencyKey: 'c2',
        goalId: 'g1',
        amountKobo: 150000,
      );
      expect(goals.findById('g1')!.savedKobo, 400000);
    });

    test('refuses an unknown goal', () async {
      await expectLater(
        service.contribute(
          idempotencyKey: 'c1',
          goalId: 'nope',
          amountKobo: 1000,
        ),
        throwsA(isA<ApiException>()),
      );
      expect(accounts.balanceKobo(), 24800000);
    });

    test('refuses more than the wallet holds', () async {
      await expectLater(
        service.contribute(
          idempotencyKey: 'c1',
          goalId: 'g1',
          amountKobo: 99900000,
        ),
        throwsA(isA<ApiException>()),
      );
      expect(goals.findById('g1')!.savedKobo, 0);
    });

    test('refuses a zero or negative amount', () async {
      await expectLater(
        service.contribute(idempotencyKey: 'c1', goalId: 'g1', amountKobo: 0),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        service.contribute(idempotencyKey: 'c2', goalId: 'g1', amountKobo: -5),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
