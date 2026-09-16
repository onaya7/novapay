import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/savings/domain/entities/goal_draft.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/domain/usecases/savings_usecases.dart';
import 'package:novapay/features/savings/presentation/cubit/contribute_cubit.dart';
import 'package:novapay/features/savings/presentation/cubit/create_goal_cubit.dart';
import 'package:novapay/features/savings/presentation/cubit/savings_cubit.dart';

class _MockLoadGoals extends Mock implements LoadGoals;

class _MockWatchGoals extends Mock implements WatchGoals;

class _MockCreateGoal extends Mock implements CreateGoal;

class _MockLoadSavable extends Mock implements LoadSavableBalance;

class _MockContribute extends Mock implements ContributeToGoal;

final _goal = SavingsGoalItem(
  id: 'g1',
  name: 'Rent',
  targetKobo: 10000000,
  savedKobo: 0,
  targetDate: DateTime(2027),
);

const _available = Money.fromKobo(2000000);

void main() {
  setUpAll(() {
    registerFallbackValue(
      NewGoalParams(name: '', target: Money.zero, targetDate: DateTime(2027)),
    );
    registerFallbackValue(
      const ContributionParams(goalId: '', amount: Money.zero),
    );
  });

  group('SavingsCubit', () {
    late _MockLoadGoals load;
    late _MockWatchGoals watch;
    late StreamController<List<SavingsGoalItem>> updates;

    setUp(() {
      load = _MockLoadGoals();
      watch = _MockWatchGoals();
      updates = StreamController<List<SavingsGoalItem>>.broadcast();
      when(() => watch(const NoParams())).thenAnswer((_) => updates.stream);
      when(() => load(const NoParams()))
          .thenAnswer((_) async => Right([_goal]));
    });

    tearDown(() => updates.close());

    test('opens on loading, so the first frame is never blank', () {
      expect(SavingsCubit(load, watch).state, const SavingsState.loading());
    });

    test('start loads once and shows the goals', () async {
      final cubit = SavingsCubit(load, watch);

      await cubit.start();

      expect(cubit.state, SavingsState.ready([_goal]));
      verify(() => load(const NoParams())).called(1);
      await cubit.close();
    });

    test('a queued contribution reaches the list without a reload', () async {
      final cubit = SavingsCubit(load, watch);
      await cubit.start();

      final updated = [_goal.copyWith(pendingKobo: 500000)];
      updates.add(updated);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, SavingsState.ready(updated));
      verify(() => load(const NoParams())).called(1);
      await cubit.close();
    });

    test('a failure is shown as copy, never as a raw failure', () async {
      when(() => load(const NoParams()))
          .thenAnswer((_) async => const Left(Failure.noInternet()));
      final cubit = SavingsCubit(load, watch);

      await cubit.start();

      expect(
        cubit.state,
        const SavingsState.failure(
          'Please check your internet connection and try again',
        ),
      );
      await cubit.close();
    });

    test('closing releases the queue subscription', () async {
      final cubit = SavingsCubit(load, watch);
      await cubit.start();
      expect(updates.hasListener, isTrue);

      await cubit.close();

      expect(updates.hasListener, isFalse);
    });
  });

  group('CreateGoalCubit', () {
    late _MockCreateGoal create;

    setUp(() {
      create = _MockCreateGoal();
      when(() => create(any())).thenAnswer((_) async => Right(_goal));
    });

    CreateGoalCubit build() => CreateGoalCubit(create);

    test('opens on an empty draft', () {
      expect(build().state, const CreateGoalState.editing(GoalDraft()));
    });

    test('a target is parsed through Money, never a double', () {
      final cubit = build()..targetChanged('0.29');

      expect(cubit.state.draft.target, const Money.fromKobo(29));
    });

    test('unparseable input falls back to zero rather than throwing', () {
      final cubit = build()..targetChanged('abc');

      expect(cubit.state.draft.target, Money.zero);
    });

    test('submit does nothing until all three are filled', () async {
      final cubit = build()..nameChanged('Rent');

      await cubit.submit();

      expect(cubit.state, isA<CreateGoalEditing>());
      verifyNever(() => create(any()));
    });

    test('a complete draft creates and finishes', () async {
      final cubit = build()
        ..nameChanged('Rent')
        ..targetChanged('100000')
        ..dateChanged(DateTime(2027));

      await cubit.submit();

      expect(cubit.state, isA<CreateGoalDone>());
      verify(
        () => create(
          NewGoalParams(
            name: 'Rent',
            target: const Money.fromKobo(10000000),
            targetDate: DateTime(2027),
          ),
        ),
      ).called(1);
    });

    test('a refusal returns to editing with copy, keeping the draft', () async {
      when(() => create(any())).thenAnswer(
        (_) async => const Left(Failure.serverError('Give the goal a name')),
      );
      final cubit = build()
        ..nameChanged('Rent')
        ..targetChanged('100000')
        ..dateChanged(DateTime(2027));

      await cubit.submit();

      expect(
        cubit.state,
        isA<CreateGoalEditing>().having(
          (s) => s.error,
          'error',
          'Give the goal a name',
        ),
      );
      expect(cubit.state.draft.name, 'Rent');
    });

    test('isSubmitting is only true while in flight', () async {
      final cubit = build()
        ..nameChanged('Rent')
        ..targetChanged('100000')
        ..dateChanged(DateTime(2027));
      final seen = <CreateGoalState>[];
      final subscription = cubit.stream.listen(seen.add);

      await cubit.submit();

      expect(seen.first, isA<CreateGoalSubmitting>());
      expect(cubit.state.isSubmitting, isFalse);
      await subscription.cancel();
    });
  });

  group('ContributeCubit', () {
    late _MockLoadSavable loadAvailable;
    late _MockContribute contribute;

    setUp(() {
      loadAvailable = _MockLoadSavable();
      contribute = _MockContribute();
      when(() => loadAvailable(const NoParams()))
          .thenAnswer((_) async => const Right(_available));
      when(() => contribute(any())).thenAnswer((_) async => const Right(unit));
    });

    ContributeCubit build() => ContributeCubit(loadAvailable, contribute);

    Future<ContributeCubit> started() async {
      final cubit = build();
      await cubit.start(_goal);
      return cubit;
    }

    test('it has no draft until the balance has loaded', () {
      expect(build().state.draft, isNull);
    });

    test('start brings in what may be spent', () async {
      final cubit = await started();

      expect(cubit.state.draft?.available, _available);
      expect(cubit.state.draft?.goal, _goal);
    });

    test('a failed balance read is shown but does not block typing', () async {
      when(() => loadAvailable(const NoParams()))
          .thenAnswer((_) async => const Left(Failure.noInternet()));
      final cubit = build();

      await cubit.start(_goal);

      expect(
        cubit.state,
        isA<ContributeEditing>().having(
          (s) => s.error,
          'error',
          'Please check your internet connection and try again',
        ),
      );
      expect(cubit.state.draft?.available, Money.zero);
    });

    test('an amount is parsed through Money', () async {
      final cubit = await started();

      cubit.amountChanged('0.29');

      expect(cubit.state.draft?.amount, const Money.fromKobo(29));
    });

    test('typing before the balance lands is ignored, not a crash', () {
      final cubit = build()..amountChanged('500');

      expect(cubit.state.draft, isNull);
    });

    test('submit queues the contribution and finishes', () async {
      final cubit = await started();
      cubit.amountChanged('5000');

      await cubit.submit();

      expect(cubit.state, isA<ContributeDone>());
      verify(
        () => contribute(
          const ContributionParams(
            goalId: 'g1',
            amount: Money.fromKobo(500000),
          ),
        ),
      ).called(1);
    });

    test('submit does nothing when more than available is entered', () async {
      final cubit = await started();
      cubit.amountChanged('999999');

      await cubit.submit();

      expect(cubit.state, isA<ContributeEditing>());
      verifyNever(() => contribute(any()));
    });

    test('submit before the balance lands does nothing', () async {
      final cubit = build();

      await cubit.submit();

      expect(cubit.state, isA<ContributeInitial>());
      verifyNever(() => contribute(any()));
    });

    test('a refusal returns to editing with copy', () async {
      when(
        () => contribute(any()),
      ).thenAnswer((_) async => const Left(Failure.serverError('Not enough')));
      final cubit = await started();
      cubit.amountChanged('5000');

      await cubit.submit();

      expect(
        cubit.state,
        isA<ContributeEditing>().having((s) => s.error, 'error', 'Not enough'),
      );
    });

    test('isSubmitting is only true while in flight', () async {
      final cubit = await started();
      cubit.amountChanged('5000');
      final seen = <ContributeState>[];
      final subscription = cubit.stream.listen(seen.add);

      await cubit.submit();

      expect(seen.first, isA<ContributeSubmitting>());
      expect(cubit.state.isSubmitting, isFalse);
      await subscription.cancel();
    });
  });
}
