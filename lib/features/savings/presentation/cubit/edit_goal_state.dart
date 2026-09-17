part of 'edit_goal_cubit.dart';

@freezed
sealed class EditGoalState with _$EditGoalState {
  const factory EditGoalState.initial() = EditGoalInitial;
  const factory EditGoalState.editing(GoalDraft draft, {String? error}) =
      EditGoalEditing;
  const factory EditGoalState.submitting(GoalDraft draft) = EditGoalSubmitting;
  const factory EditGoalState.done(GoalDraft draft) = EditGoalDone;

  const EditGoalState._();

  /// Null only before the goal to edit has been seeded, which is the one
  /// frame the screen has nothing to render. Every later phase declares
  /// `draft` as a field, which overrides this.
  GoalDraft? get draft => null;

  bool get isSubmitting => this is EditGoalSubmitting;
}
