import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/domain/repositories/savings_repository.dart';

@lazySingleton
class LoadGoals implements UseCase<List<SavingsGoalItem>, NoParams> {
  const LoadGoals(this._repository);

  final SavingsRepository _repository;

  @override
  Future<Either<Failure, List<SavingsGoalItem>>> call(NoParams params) =>
      _repository.goals();
}

@lazySingleton
class WatchGoals implements StreamUseCase<List<SavingsGoalItem>, NoParams> {
  const WatchGoals(this._repository);

  final SavingsRepository _repository;

  @override
  Stream<List<SavingsGoalItem>> call(NoParams params) => _repository.watch();
}

@lazySingleton
class LoadSavableBalance implements UseCase<Money, NoParams> {
  const LoadSavableBalance(this._repository);

  final SavingsRepository _repository;

  @override
  Future<Either<Failure, Money>> call(NoParams params) =>
      _repository.available();
}

class NewGoalParams extends Equatable {
  const NewGoalParams({
    required this.name,
    required this.target,
    required this.targetDate,
  });

  final String name;
  final Money target;
  final DateTime targetDate;

  @override
  List<Object?> get props => [name, target, targetDate];
}

@lazySingleton
class CreateGoal implements UseCase<SavingsGoalItem, NewGoalParams> {
  const CreateGoal(this._repository);

  final SavingsRepository _repository;

  @override
  Future<Either<Failure, SavingsGoalItem>> call(NewGoalParams params) =>
      _repository.createGoal(
        name: params.name,
        target: params.target,
        targetDate: params.targetDate,
      );
}

class UpdateGoalParams extends Equatable {
  const UpdateGoalParams({
    required this.goalId,
    required this.name,
    required this.target,
    required this.targetDate,
  });

  final String goalId;
  final String name;
  final Money target;
  final DateTime targetDate;

  @override
  List<Object?> get props => [goalId, name, target, targetDate];
}

@lazySingleton
class UpdateGoal implements UseCase<SavingsGoalItem, UpdateGoalParams> {
  const UpdateGoal(this._repository);

  final SavingsRepository _repository;

  @override
  Future<Either<Failure, SavingsGoalItem>> call(UpdateGoalParams params) =>
      _repository.updateGoal(
        goalId: params.goalId,
        name: params.name,
        target: params.target,
        targetDate: params.targetDate,
      );
}

class DeleteGoalParams extends Equatable {
  const DeleteGoalParams({required this.goalId});

  final String goalId;

  @override
  List<Object?> get props => [goalId];
}

@lazySingleton
class DeleteGoal implements UseCase<Unit, DeleteGoalParams> {
  const DeleteGoal(this._repository);

  final SavingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteGoalParams params) =>
      _repository.deleteGoal(params.goalId);
}

class ContributionParams extends Equatable {
  const ContributionParams({required this.goalId, required this.amount});

  final String goalId;
  final Money amount;

  @override
  List<Object?> get props => [goalId, amount];
}

@lazySingleton
class ContributeToGoal implements UseCase<Unit, ContributionParams> {
  const ContributeToGoal(this._repository);

  final SavingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ContributionParams params) =>
      _repository.contribute(goalId: params.goalId, amount: params.amount);
}
