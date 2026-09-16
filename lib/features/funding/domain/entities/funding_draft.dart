import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/money/money.dart';

part 'funding_draft.freezed.dart';

/// The most one top-up may carry, so a mistyped amount is caught on the device.
const Money kMaxTopUp = Money.fromKobo(50000000);

/// An amount on its way into the wallet, against the balance it will join.
@freezed
abstract class FundingDraft with _$FundingDraft {
  const factory FundingDraft({
    @Default(Money.zero) Money amount,
    @Default(Money.zero) Money balance,
  }) = _FundingDraft;

  const FundingDraft._();

  bool get amountIsEntered => amount.kobo > 0;

  bool get withinLimit => amount <= kMaxTopUp;

  Money get projected => balance + amount;

  bool get canSubmit => amountIsEntered && withinLimit;
}
