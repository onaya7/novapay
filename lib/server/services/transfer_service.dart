import 'package:injectable/injectable.dart';
import 'package:novapay/core/time/clock.dart';
import 'package:novapay/server/api_exception.dart';
import 'package:novapay/server/models/transaction.dart';
import 'package:novapay/server/repositories/account_repository.dart';
import 'package:novapay/server/repositories/idempotency_repository.dart';
import 'package:novapay/server/repositories/transaction_repository.dart';

abstract class TransferService {
  /// Debits the wallet and records the transfer, returning the ledger entry.
  ///
  /// Throws [ApiException] when the transfer is refused.
  Future<Transaction> execute({
    required String idempotencyKey,
    required String recipient,
    required int amountKobo,
    String? bankName,
  });
}

@LazySingleton(as: TransferService)
class TransferServiceImpl implements TransferService {
  TransferServiceImpl(
    this._accounts,
    this._transactions,
    this._idempotency,
    this._clock,
  );

  final AccountRepository _accounts;
  final TransactionRepository _transactions;
  final IdempotencyRepository _idempotency;
  final Clock _clock;

  /// A key that has already been applied is a replay, so the original entry is
  /// returned without moving money again. That is what a real idempotent
  /// endpoint does, and it is what makes a retry after a crash safe.
  @override
  Future<Transaction> execute({
    required String idempotencyKey,
    required String recipient,
    required int amountKobo,
    String? bankName,
  }) async {
    if (_idempotency.hasSeen(idempotencyKey)) {
      final existing = _transactions.findById(idempotencyKey);
      if (existing != null) return existing;
    }

    if (amountKobo <= 0) {
      throw const ApiException('Enter an amount greater than zero');
    }

    final balance = _accounts.balanceKobo();
    if (amountKobo > balance) {
      throw const ApiException('Not enough in your wallet');
    }

    final transaction = Transaction(
      id: idempotencyKey,
      title: bankName == null
          ? 'Transfer to $recipient'
          : 'Transfer to $bankName',
      amountKobo: -amountKobo,
      occurredAt: _clock.now(),
    );

    await _accounts.setBalanceKobo(balance - amountKobo);
    await _transactions.insert(transaction);
    await _idempotency.record(idempotencyKey);
    return transaction;
  }
}
