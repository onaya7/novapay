import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/money/money.dart';

part 'transfer_receipt.freezed.dart';

/// What the customer is told after the queue accepts a transfer.
@freezed
abstract class TransferReceipt with _$TransferReceipt {
  const factory TransferReceipt({
    required String reference,
    required String bankName,
    required String recipient,
    required Money amount,
    required bool settled,
  }) = _TransferReceipt;

  const TransferReceipt._();

  /// Queued but not yet acknowledged, which is the offline case and the
  /// timed-out case alike — the app cannot tell them apart, so it says so.
  bool get isPending => !settled;
}
