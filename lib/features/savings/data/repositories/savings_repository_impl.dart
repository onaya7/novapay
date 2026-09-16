import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/exception/app_exceptions.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_service.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/domain/repositories/savings_repository.dart';
import 'package:novapay/server/models/api_response.dart';
import 'package:novapay/server/models/savings_goal.dart';
import 'package:novapay/server/novapay_api.dart';
import 'package:novapay/utils/either_safe_runner.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: SavingsRepository)
class SavingsRepositoryImpl implements SavingsRepository {
  const SavingsRepositoryImpl(this._api, this._sync, this._runner, this._uuid);

  final NovaPayApi _api;
  final SyncService _sync;
  final EitherSafeRunner _runner;
  final Uuid _uuid;

  @override
  Future<Either<Failure, List<SavingsGoalItem>>> goals() =>
      _runner(safeCallback: () async => _goals());

  @override
  Stream<List<SavingsGoalItem>> watch() => _sync.changes.map((_) => _goals());

  @override
  Future<Either<Failure, Money>> available() =>
      _runner(safeCallback: () async => _available());

  /// Not queued: creating a goal moves no money, so it is safe to require a
  /// connection and simply ask again rather than carry a durable intent.
  @override
  Future<Either<Failure, SavingsGoalItem>> createGoal({
    required String name,
    required Money target,
    required DateTime targetDate,
  }) => _runner(
    safeCallback: () async {
      final response = await _api.createGoal(
        id: _uuid.v4(),
        name: name,
        targetKobo: target.kobo,
        targetDate: targetDate,
      );
      return _toItem(_unwrap(response), pendingKobo: 0);
    },
  );

  /// Queued, because this one does move money.
  @override
  Future<Either<Failure, Unit>> contribute({
    required String goalId,
    required Money amount,
  }) => _runner(
    safeCallback: () async {
      if (amount > _available()) {
        throw const AppException.server(
          'Not enough in your wallet for this contribution',
        );
      }
      await _sync.enqueue(
        type: PendingActionType.contribute,
        amountKobo: amount.kobo,
        payload: {'goalId': goalId},
      );
      return unit;
    },
  );

  List<SavingsGoalItem> _goals() {
    final queued = _pendingByGoal();
    return [
      for (final goal in _unwrap(_api.goals()))
        _toItem(goal, pendingKobo: queued[goal.id] ?? 0),
    ]..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }

  /// Contributions still owed, summed per goal, so a card can show money that
  /// has left the wallet but has not reached the goal yet.
  Map<String, int> _pendingByGoal() {
    final totals = <String, int>{};
    for (final action in _sync.pending()) {
      if (action.type != PendingActionType.contribute) continue;
      final goalId = action.payload['goalId'];
      if (goalId is! String) continue;
      totals[goalId] = (totals[goalId] ?? 0) + action.amountKobo;
    }
    return totals;
  }

  SavingsGoalItem _toItem(SavingsGoal goal, {required int pendingKobo}) =>
      SavingsGoalItem(
        id: goal.id,
        name: goal.name,
        targetKobo: goal.targetKobo,
        savedKobo: goal.savedKobo,
        targetDate: goal.targetDate,
        pendingKobo: pendingKobo,
      );

  Money _available() {
    final balance = _api.balance();
    if (!balance.isSuccess) throw AppException.server(balance.message);
    return availableBalance(
      confirmed: Money.fromKobo(balance.requireData),
      pending: Money.fromKobo(_sync.pendingKobo()),
    );
  }

  T _unwrap<T>(ApiResponse<T> response) {
    if (!response.isSuccess) throw AppException.server(response.message);
    return response.requireData;
  }
}
