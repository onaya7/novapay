import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/domain/repositories/savings_repository.dart';
import 'package:novapay/features/savings/domain/usecases/savings_usecases.dart';

class _MockSavingsRepository extends Mock implements SavingsRepository;

final _goal = SavingsGoalItem(
  id: 'g1',
  name: 'Rent',
  targetKobo: 10000000,
  savedKobo: 0,
  targetDate: DateTime(2027),
);

void main() {
  late _MockSavingsRepository repository;

  setUpAll(() => registerFallbackValue(Money.zero));

  setUp(() => repository = _MockSavingsRepository());

  test('LoadGoals hands back whatever the repository resolved', () async {
    when(repository.goals).thenAnswer((_) async => Right([_goal]));

    final result = await LoadGoals(repository)(const NoParams());

    // dartz compares with ==, and two distinct lists are never equal, so the
    // payload is unwrapped rather than the Right compared whole.
    expect(result.getOrElse(() => []), [_goal]);
    verify(repository.goals).called(1);
  });

  test('LoadGoals passes a failure through untouched', () async {
    when(repository.goals)
        .thenAnswer((_) async => const Left(Failure.noInternet()));

    final result = await LoadGoals(repository)(const NoParams());

    expect(
      result,
      const Left<Failure, List<SavingsGoalItem>>(Failure.noInternet()),
    );
  });

  test('WatchGoals forwards the repository stream', () {
    when(repository.watch).thenAnswer((_) => Stream.value([_goal]));

    expect(
      WatchGoals(repository)(const NoParams()),
      emitsInOrder([
        [_goal],
        emitsDone,
      ]),
    );
  });

  test('LoadSavableBalance delegates', () async {
    when(repository.available)
        .thenAnswer((_) async => const Right(Money.fromKobo(100)));

    final result = await LoadSavableBalance(repository)(const NoParams());

    expect(result, const Right<Failure, Money>(Money.fromKobo(100)));
  });

  test('CreateGoal hands the params through unchanged', () async {
    when(
      () => repository.createGoal(
        name: any(named: 'name'),
        target: any(named: 'target'),
        targetDate: any(named: 'targetDate'),
      ),
    ).thenAnswer((_) async => Right(_goal));

    final result = await CreateGoal(repository)(
      NewGoalParams(
        name: 'Rent',
        target: const Money.fromKobo(100),
        targetDate: DateTime(2027),
      ),
    );

    expect(result.getOrElse(() => throw StateError('expected a goal')), _goal);
    verify(
      () => repository.createGoal(
        name: 'Rent',
        target: const Money.fromKobo(100),
        targetDate: DateTime(2027),
      ),
    ).called(1);
  });

  test('ContributeToGoal hands the params through unchanged', () async {
    when(
      () => repository.contribute(
        goalId: any(named: 'goalId'),
        amount: any(named: 'amount'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    final result = await ContributeToGoal(repository)(
      const ContributionParams(goalId: 'g1', amount: Money.fromKobo(500000)),
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(
      () => repository.contribute(
        goalId: 'g1',
        amount: const Money.fromKobo(500000),
      ),
    ).called(1);
  });

  test('the params are values, so two identical ones match', () {
    expect(
      NewGoalParams(name: 'a', target: Money.zero, targetDate: DateTime(2027)),
      NewGoalParams(name: 'a', target: Money.zero, targetDate: DateTime(2027)),
    );
    expect(
      const ContributionParams(goalId: 'g', amount: Money.zero),
      const ContributionParams(goalId: 'g', amount: Money.zero),
    );
    expect(const ContributionParams(goalId: 'g', amount: Money.zero).props, [
      'g',
      Money.zero,
    ]);
  });
}
