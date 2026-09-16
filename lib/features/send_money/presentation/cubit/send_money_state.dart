part of 'send_money_cubit.dart';

@freezed
sealed class SendMoneyState with _$SendMoneyState {
  const factory SendMoneyState.editing(TransferDraft draft, {String? error}) =
      SendMoneyEditing;
  const factory SendMoneyState.submitting(TransferDraft draft) =
      SendMoneySubmitting;
  const factory SendMoneyState.done(
    TransferDraft draft,
    TransferReceipt receipt,
  ) = SendMoneyDone;

  const SendMoneyState._();

  bool get isSubmitting => this is SendMoneySubmitting;
}
