import 'package:dartz/dartz.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';

abstract class SavingsRepository {
  Future<Either<Failure, List<SavingsGoalItem>>> goals();

  /// Re-emits whenever the queue changes, so a contribution shows at once.
  Stream<List<SavingsGoalItem>> watch();

  Future<Either<Failure, Money>> available();

  Future<Either<Failure, SavingsGoalItem>> createGoal({
    required String name,
    required Money target,
    required DateTime targetDate,
  });

  /// Not queued, like [createGoal]: moves no money.
  Future<Either<Failure, SavingsGoalItem>> updateGoal({
    required String goalId,
    required String name,
    required Money target,
    required DateTime targetDate,
  });

  /// Not queued. Refuses while a contribution is still pending for this goal.
  Future<Either<Failure, Unit>> deleteGoal(String goalId);

  /// Queued, not sent: money moving must survive being offline.
  Future<Either<Failure, Unit>> contribute({
    required String goalId,
    required Money amount,
  });
}
