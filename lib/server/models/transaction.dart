import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/money/money.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// A settled movement of money on the wallet. Negative [amountKobo] is money
/// leaving.
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String title,
    // koboFromJson throws rather than coercing; the generated default would
    // call num.toInt() and silently truncate.
    @JsonKey(fromJson: koboFromJson) required int amountKobo,
    required DateTime occurredAt,
  }) = _Transaction;

  const Transaction._();

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Money get amount => Money.fromKobo(amountKobo);

  bool get isDebit => amountKobo < 0;
}
