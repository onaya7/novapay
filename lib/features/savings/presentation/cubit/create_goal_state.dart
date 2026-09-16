part of 'create_goal_cubit.dart';

@freezed
sealed class CreateGoalState with _$CreateGoalState {
  const factory CreateGoalState.editing(GoalDraft draft, {String? error}) =
      CreateGoalEditing;
  const factory CreateGoalState.submitting(GoalDraft draft) =
      CreateGoalSubmitting;
  const factory CreateGoalState.done(GoalDraft draft) = CreateGoalDone;

  const CreateGoalState._();

  bool get isSubmitting => this is CreateGoalSubmitting;
}
