import 'package:injectable/injectable.dart';
import 'package:novapay/server/api_exception.dart';
import 'package:novapay/server/models/savings_goal.dart';
import 'package:novapay/server/models/transaction.dart';
import 'package:novapay/server/repositories/account_repository.dart';
import 'package:novapay/server/repositories/idempotency_repository.dart';
import 'package:novapay/server/repositories/savings_goal_repository.dart';
import 'package:novapay/server/repositories/transaction_repository.dart';

abstract class SavingsService {
  /// Throws [ApiException] when the goal is not valid.
  Future<SavingsGoal> createGoal({
    required String id,
    required String name,
    required int targetKobo,
    required DateTime targetDate,
  });

  /// Moves money from the wallet into a goal and returns the updated goal.
  ///
  /// Throws [ApiException] when the contribution is refused.
  Future<SavingsGoal> contribute({
    required String idempotencyKey,
    required String goalId,
    required int amountKobo,
  });
}

@LazySingleton(as: SavingsService)
class SavingsServiceImpl implements SavingsService {
  SavingsServiceImpl(
    this._goals,
    this._accounts,
    this._transactions,
    this._idempotency,
  );

  final SavingsGoalRepository _goals;
  final AccountRepository _accounts;
  final TransactionRepository _transactions;
  final IdempotencyRepository _idempotency;

  @override
  Future<SavingsGoal> createGoal({
    required String id,
    required String name,
    required int targetKobo,
    required DateTime targetDate,
  }) async {
    if (name.trim().isEmpty) {
      throw const ApiException('Give the goal a name');
    }
    if (targetKobo <= 0) {
      throw const ApiException('Set a target greater than zero');
    }

    final goal = SavingsGoal(
      id: id,
      name: name.trim(),
      targetKobo: targetKobo,
      targetDate: targetDate,
    );
    await _goals.insert(goal);
    return goal;
  }

  /// A replayed key returns the goal as it already stands, without adding the
  /// amount a second time.
  @override
  Future<SavingsGoal> contribute({
    required String idempotencyKey,
    required String goalId,
    required int amountKobo,
  }) async {
    final goal = _goals.findById(goalId);
    if (goal == null) {
      throw const ApiException('That goal no longer exists');
    }
    if (_idempotency.hasSeen(idempotencyKey)) return goal;

    if (amountKobo <= 0) {
      throw const ApiException('Enter an amount greater than zero');
    }

    final balance = _accounts.balanceKobo();
    if (amountKobo > balance) {
      throw const ApiException('Not enough in your wallet');
    }

    final updated = goal.copyWith(savedKobo: goal.savedKobo + amountKobo);
    await _accounts.setBalanceKobo(balance - amountKobo);
    await _goals.update(updated);
    await _transactions.insert(
      Transaction(
        id: idempotencyKey,
        title: 'Saved to ${goal.name}',
        amountKobo: -amountKobo,
        occurredAt: DateTime.now(),
      ),
    );
    await _idempotency.record(idempotencyKey);
    return updated;
  }
}
