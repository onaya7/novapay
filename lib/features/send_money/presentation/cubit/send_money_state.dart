part of 'send_money_cubit.dart';

@freezed
sealed class SendMoneyState with _$SendMoneyState {
  const factory SendMoneyState.editing(
    TransferDraft draft, {
    @Default(<Bank>[]) List<Bank> banks,
    String? error,
  }) = SendMoneyEditing;
  const factory SendMoneyState.submitting(TransferDraft draft) =
      SendMoneySubmitting;
  const factory SendMoneyState.done(
    TransferDraft draft,
    TransferReceipt receipt,
  ) = SendMoneyDone;

  const SendMoneyState._();

  /// Empty outside `editing`: nothing else lets the customer pick a bank.
  List<Bank> get banks => const [];

  bool get isSubmitting => this is SendMoneySubmitting;
}
