import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/exception/app_exceptions.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_service.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_receipt.dart';
import 'package:novapay/features/send_money/domain/repositories/transfer_repository.dart';
import 'package:novapay/server/novapay_api.dart';
import 'package:novapay/utils/either_safe_runner.dart';

@LazySingleton(as: TransferRepository)
class TransferRepositoryImpl implements TransferRepository {
  const TransferRepositoryImpl(this._api, this._sync, this._runner);

  final NovaPayApi _api;
  final SyncService _sync;
  final EitherSafeRunner _runner;

  @override
  Future<Either<Failure, Money>> available() =>
      _runner(safeCallback: () async => _available());

  /// Saves the transfer before trying to send it, so the money is never
  /// riding on a network call that may not come back.
  @override
  Future<Either<Failure, TransferReceipt>> queue({
    required String bankCode,
    required String bankName,
    required String recipient,
    required Money amount,
  }) => _runner(
    safeCallback: () async {
      // The screen blocks this too; here it guards the balance moving between
      // the confirm screen opening and the button being pressed.
      if (amount > _available()) {
        throw const AppException.server(
          'Not enough in your wallet for this transfer',
        );
      }

      final action = await _sync.enqueue(
        type: PendingActionType.send,
        amountKobo: amount.kobo,
        payload: {
          'recipient': recipient,
          'bankCode': bankCode,
          'bankName': bankName,
        },
      );

      return TransferReceipt(
        reference: action.id,
        bankName: bankName,
        recipient: recipient,
        amount: amount,
        settled: _settled(action.id),
      );
    },
  );

  Money _available() {
    final balance = _api.balance();
    if (!balance.isSuccess) throw AppException.server(balance.message);
    return availableBalance(
      confirmed: Money.fromKobo(balance.requireData),
      pending: Money.fromKobo(_sync.pendingKobo()),
    );
  }

  bool _settled(String id) => _sync.actions().any(
    (a) => a.id == id && a.status == PendingActionStatus.done,
  );
}
