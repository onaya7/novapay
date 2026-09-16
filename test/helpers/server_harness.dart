import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/server/novapay_api.dart';
import 'package:novapay/server/repositories/account_repository.dart';
import 'package:novapay/server/repositories/idempotency_repository.dart';
import 'package:novapay/server/repositories/savings_goal_repository.dart';
import 'package:novapay/server/repositories/transaction_repository.dart';
import 'package:novapay/server/services/savings_service.dart';
import 'package:novapay/server/services/transfer_service.dart';

/// Wires a whole server over [db], the way the DI container does in the app.
///
/// Returns the implementation rather than [NovaPayApi], because tests need the
/// demo affordances the interface deliberately withholds.
NovaPayApiImpl buildApi(LocalDataStorage db, {Duration? latency}) {
  final accounts = AccountRepositoryImpl(db);
  final transactions = TransactionRepositoryImpl(db);
  final goals = SavingsGoalRepositoryImpl(db);
  final idempotency = IdempotencyRepositoryImpl(db);
  return NovaPayApiImpl(
    TransferServiceImpl(accounts, transactions, idempotency),
    SavingsServiceImpl(goals, accounts, transactions, idempotency),
    accounts,
    transactions,
    goals,
    idempotency,
  )..latency = latency ?? Duration.zero;
}
