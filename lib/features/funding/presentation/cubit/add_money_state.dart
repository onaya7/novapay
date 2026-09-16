part of 'add_money_cubit.dart';

@freezed
sealed class AddMoneyState with _$AddMoneyState {
  const factory AddMoneyState.initial() = AddMoneyInitial;
  const factory AddMoneyState.editing(FundingDraft draft, {String? error}) =
      AddMoneyEditing;
  const factory AddMoneyState.submitting(FundingDraft draft) =
      AddMoneySubmitting;
  const factory AddMoneyState.done(FundingDraft draft) = AddMoneyDone;

  const AddMoneyState._();

  /// Null only before the balance has loaded, which is the one frame the
  /// screen has nothing to render. Every later phase declares `draft` as a
  /// field, which overrides this.
  FundingDraft? get draft => null;

  bool get isSubmitting => this is AddMoneySubmitting;
}
