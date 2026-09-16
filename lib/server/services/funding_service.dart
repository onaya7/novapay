import 'package:injectable/injectable.dart';
import 'package:novapay/core/time/clock.dart';
import 'package:novapay/server/api_exception.dart';
import 'package:novapay/server/models/transaction.dart';
import 'package:novapay/server/repositories/account_repository.dart';
import 'package:novapay/server/repositories/idempotency_repository.dart';
import 'package:novapay/server/repositories/transaction_repository.dart';

abstract class FundingService {
  /// Credits the wallet and records the entry, returning it.
  ///
  /// Throws [ApiException] when the amount is not one.
  Future<Transaction> execute({
    required String idempotencyKey,
    required int amountKobo,
  });
}

@LazySingleton(as: FundingService)
class FundingServiceImpl implements FundingService {
  FundingServiceImpl(
    this._accounts,
    this._transactions,
    this._idempotency,
    this._clock,
  );

  final AccountRepository _accounts;
  final TransactionRepository _transactions;
  final IdempotencyRepository _idempotency;
  final Clock _clock;

  /// Idempotent like every other money move: a replayed key returns the
  /// original entry rather than crediting twice.
  @override
  Future<Transaction> execute({
    required String idempotencyKey,
    required int amountKobo,
  }) async {
    if (_idempotency.hasSeen(idempotencyKey)) {
      final existing = _transactions.findById(idempotencyKey);
      if (existing != null) return existing;
    }

    if (amountKobo <= 0) {
      throw const ApiException('Enter an amount greater than zero');
    }

    final transaction = Transaction(
      id: idempotencyKey,
      title: 'Added to wallet',
      amountKobo: amountKobo,
      occurredAt: _clock.now(),
    );

    await _accounts.setBalanceKobo(_accounts.balanceKobo() + amountKobo);
    await _transactions.insert(transaction);
    await _idempotency.record(idempotencyKey);
    return transaction;
  }
}
