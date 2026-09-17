import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/extensions/string_extension.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/send_money/domain/entities/bank.dart';

part 'transfer_draft.freezed.dart';

enum SendStep { recipient, amount, confirm }

/// What the customer has filled in so far, plus the rules that decide whether
/// they may go on. The screen asks this, so no rule lives in a widget.
@freezed
abstract class TransferDraft with _$TransferDraft {
  const factory TransferDraft({
    @Default(SendStep.recipient) SendStep step,
    Bank? bank,
    @Default('') String recipient,
    @Default(Money.zero) Money amount,
    @Default(Money.zero) Money available,
  }) = _TransferDraft;

  const TransferDraft._();

  bool get recipientIsValid => bank != null && recipient.isAccountNumber;

  bool get amountIsEntered => amount.kobo > 0;

  /// Committed money is already gone, so this compares against available.
  bool get hasEnough => amount <= available;

  Money get remaining => available - amount;

  /// A blocked screen keeps a live call to action; only an empty one is dead.
  bool get canAdvance => switch (step) {
    SendStep.recipient => recipientIsValid,
    SendStep.amount => amountIsEntered,
    SendStep.confirm => amountIsEntered && recipientIsValid && hasEnough,
  };

  SendStep? get previousStep => switch (step) {
    SendStep.recipient => null,
    SendStep.amount => SendStep.recipient,
    SendStep.confirm => SendStep.amount,
  };

  SendStep? get nextStep => switch (step) {
    SendStep.recipient => SendStep.amount,
    SendStep.amount => SendStep.confirm,
    SendStep.confirm => null,
  };
}
