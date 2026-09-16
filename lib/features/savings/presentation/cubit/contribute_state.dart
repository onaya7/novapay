part of 'contribute_cubit.dart';

@freezed
sealed class ContributeState with _$ContributeState {
  const factory ContributeState.initial() = ContributeInitial;
  const factory ContributeState.editing(
    ContributionDraft draft, {
    String? error,
  }) = ContributeEditing;
  const factory ContributeState.submitting(ContributionDraft draft) =
      ContributeSubmitting;
  const factory ContributeState.done(ContributionDraft draft) = ContributeDone;

  const ContributeState._();

  /// Null only before the balance has loaded, which is the one frame the
  /// screen has nothing to render. Every later phase declares `draft` as a
  /// field, which overrides this.
  ContributionDraft? get draft => null;

  bool get isSubmitting => this is ContributeSubmitting;
}
