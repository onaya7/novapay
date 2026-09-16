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
import 'package:novapay/features/savings/data/repositories/savings_repository_impl.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/server/models/api_response.dart';
import 'package:novapay/server/models/savings_goal.dart';
import 'package:novapay/server/novapay_api.dart';
import 'package:novapay/utils/either_safe_runner.dart';
import 'package:uuid/uuid.dart';

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
  late SavingsRepositoryImpl repository;

  void online({required bool connected}) {
    when(() => network.isConnected).thenAnswer((_) async => connected);
  }

  Future<SavingsGoalItem> createGoal({
    String name = 'Rent',
    int targetKobo = 10000000,
    int daysAhead = 30,
  }) async {
    final result = await repository.createGoal(
      name: name,
      target: Money.fromKobo(targetKobo),
      targetDate: DateTime.now().add(Duration(days: daysAhead)),
    );
    return result.getOrElse(() => throw StateError('expected a goal'));
  }

  Future<List<SavingsGoalItem>> goals() async {
    final result = await repository.goals();
    return result.getOrElse(() => throw StateError('expected goals'));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_savings');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('savings_test');
    db = LocalDataStorageImpl(box);
    backend = buildApi(db);
    network = _MockNetworkInfo();
    sync = SyncServiceImpl(db, backend, network);
    repository = SavingsRepositoryImpl(
      backend,
      sync,
      const EitherSafeRunner(),
      const Uuid(),
    );
    online(connected: true);
  });

  tearDown(() async {
    await sync.dispose();
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('createGoal', () {
    test('a new goal starts empty and is listed', () async {
      final goal = await createGoal();

      expect(goal.name, 'Rent');
      expect(goal.savedKobo, 0);
      expect(goal.pendingKobo, 0);
      expect(await goals(), hasLength(1));
    });

    test('the server refuses a nameless goal as a Failure', () async {
      final result = await repository.createGoal(
        name: '  ',
        target: const Money.fromKobo(100),
        targetDate: DateTime.now(),
      );

      expect(
        result,
        const Left<Failure, SavingsGoalItem>(
          Failure.serverError('Give the goal a name'),
        ),
      );
    });

    test('the server refuses a zero target', () async {
      final result = await repository.createGoal(
        name: 'Rent',
        target: Money.zero,
        targetDate: DateTime.now(),
      );

      expect(result.isLeft(), isTrue);
    });

    test('creating needs a network, because nothing is queued', () async {
      final api = _MockApi();
      when(
        () => api.createGoal(
          id: any(named: 'id'),
          name: any(named: 'name'),
          targetKobo: any(named: 'targetKobo'),
          targetDate: any(named: 'targetDate'),
        ),
      ).thenThrow(Exception('offline'));
      final failing = SavingsRepositoryImpl(
        api,
        sync,
        const EitherSafeRunner(),
        const Uuid(),
      );

      final result = await failing.createGoal(
        name: 'Rent',
        target: const Money.fromKobo(100),
        targetDate: DateTime.now(),
      );

      expect(result, const Left<Failure, SavingsGoalItem>(Failure.unknown()));
    });
  });

  group('goals', () {
    test('they come back ordered by target date, soonest first', () async {
      await createGoal(name: 'Later', daysAhead: 90);
      await createGoal(name: 'Sooner', daysAhead: 10);

      expect((await goals()).map((g) => g.name), ['Sooner', 'Later']);
    });

    test('a queued contribution shows before it settles', () async {
      final goal = await createGoal();
      online(connected: false);
      await repository.contribute(
        goalId: goal.id,
        amount: const Money.fromKobo(2500000),
      );

      final listed = (await goals()).single;

      expect(listed.savedKobo, 0);
      expect(listed.pendingKobo, 2500000);
      expect(listed.percentComplete, 25);
      expect(listed.hasPending, isTrue);
    });

    test('once it drains the money is settled, not double counted', () async {
      final goal = await createGoal();
      await repository.contribute(
        goalId: goal.id,
        amount: const Money.fromKobo(2500000),
      );

      final listed = (await goals()).single;

      expect(listed.savedKobo, 2500000);
      expect(listed.pendingKobo, 0);
      expect(listed.projected, const Money.fromKobo(2500000));
    });

    test('queued amounts are summed per goal, not mixed', () async {
      final rent = await createGoal(daysAhead: 10);
      final trip = await createGoal(name: 'Trip', daysAhead: 20);
      online(connected: false);
      await repository.contribute(
        goalId: rent.id,
        amount: const Money.fromKobo(100000),
      );
      await repository.contribute(
        goalId: rent.id,
        amount: const Money.fromKobo(200000),
      );
      await repository.contribute(
        goalId: trip.id,
        amount: const Money.fromKobo(50000),
      );

      final listed = await goals();

      expect(listed.first.pendingKobo, 300000);
      expect(listed.last.pendingKobo, 50000);
    });

    test('a refused read becomes a Failure', () async {
      final api = _MockApi();
      when(api.goals).thenReturn(
        ApiResponse<List<SavingsGoal>>.failure(
          code: 503,
          message: 'Savings unavailable',
        ),
      );
      final failing = SavingsRepositoryImpl(
        api,
        sync,
        const EitherSafeRunner(),
        const Uuid(),
      );

      expect((await failing.goals()).isLeft(), isTrue);
    });
  });

  group('contribute', () {
    test(
      'it is queued rather than sent, so it survives being offline',
      () async {
        final goal = await createGoal();
        online(connected: false);

        final result = await repository.contribute(
          goalId: goal.id,
          amount: const Money.fromKobo(2500000),
        );

        expect(result.isRight(), isTrue);
        expect(sync.pending(), hasLength(1));
        expect(backend.goal(goal.id).requireData.savedKobo, 0);
      },
    );

    test('more than is available is refused before it is queued', () async {
      final goal = await createGoal();

      final result = await repository.contribute(
        goalId: goal.id,
        amount: const Money.fromKobo(99900000),
      );

      expect(
        result,
        const Left<Failure, Unit>(
          Failure.serverError(
            'Not enough in your wallet for this contribution',
          ),
        ),
      );
      expect(sync.actions(), isEmpty);
    });

    test('available already counts what is queued elsewhere', () async {
      final goal = await createGoal();
      online(connected: false);
      await repository.contribute(
        goalId: goal.id,
        amount: const Money.fromKobo(24000000),
      );

      final result = await repository.available();

      expect(result, const Right<Failure, Money>(Money.fromKobo(800000)));
    });
  });

  group('watch', () {
    test('re-emits with the new pending total when the queue moves', () async {
      final goal = await createGoal();
      online(connected: false);
      final seen = <List<SavingsGoalItem>>[];
      final subscription = repository.watch().listen(seen.add);

      await repository.contribute(
        goalId: goal.id,
        amount: const Money.fromKobo(2500000),
      );
      await Future<void>.delayed(Duration.zero);

      expect(seen, isNotEmpty);
      expect(seen.last.single.pendingKobo, 2500000);

      await subscription.cancel();
    });
  });
}
