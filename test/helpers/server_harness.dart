import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/core/time/clock.dart';
import 'package:novapay/server/novapay_api.dart';
import 'package:novapay/server/repositories/account_repository.dart';
import 'package:novapay/server/repositories/idempotency_repository.dart';
import 'package:novapay/server/repositories/savings_goal_repository.dart';
import 'package:novapay/server/repositories/transaction_repository.dart';
import 'package:novapay/server/services/savings_service.dart';
import 'package:novapay/server/services/transfer_service.dart';

/// A clock the test moves by hand, so a backoff window can be crossed without
/// waiting for it.
class TestClock implements Clock {
  TestClock([DateTime? start]) : _now = start ?? DateTime(2026, 9, 16, 12);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

/// Wires a whole server over [db], the way the DI container does in the app.
///
/// Returns the implementation rather than [NovaPayApi], because tests need the
/// demo affordances the interface deliberately withholds.
NovaPayApiImpl buildApi(
  LocalDataStorage db, {
  Duration? latency,
  Clock? clock,
}) {
  // The same clock the queue gets, so a settled row and a queued one can be
  // ordered against each other.
  final time = clock ?? TestClock();
  final accounts = AccountRepositoryImpl(db);
  final transactions = TransactionRepositoryImpl(db);
  final goals = SavingsGoalRepositoryImpl(db);
  final idempotency = IdempotencyRepositoryImpl(db);
  return NovaPayApiImpl(
    TransferServiceImpl(accounts, transactions, idempotency, time),
    SavingsServiceImpl(goals, accounts, transactions, idempotency, time),
    accounts,
    transactions,
    goals,
    idempotency,
  )..latency = latency ?? Duration.zero;
}
