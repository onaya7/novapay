import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/savings/domain/entities/goal_draft.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/domain/usecases/savings_usecases.dart';

part 'edit_goal_cubit.freezed.dart';
part 'edit_goal_state.dart';

@injectable
class EditGoalCubit extends Cubit<EditGoalState> {
  EditGoalCubit(this._updateGoal) : super(const EditGoalState.initial());

  final UpdateGoal _updateGoal;

  static const ConvertFailureToString _toMessage = ConvertFailureToString();

  GoalDraft? get _draft => state.draft;

  Future<void> start(SavingsGoalItem goal) async {
    emit(
      EditGoalState.editing(
        GoalDraft(
          id: goal.id,
          name: goal.name,
          target: goal.target,
          targetDate: goal.targetDate,
        ),
      ),
    );
  }

  void nameChanged(String value) {
    final draft = _draft;
    if (draft == null) return;
    emit(EditGoalState.editing(draft.copyWith(name: value)));
  }

  /// Parses through [Money], so a typed target never becomes a double.
  void targetChanged(String value) {
    final draft = _draft;
    if (draft == null) return;
    emit(
      EditGoalState.editing(
        draft.copyWith(target: Money.tryParse(value) ?? Money.zero),
      ),
    );
  }

  void dateChanged(DateTime value) {
    final draft = _draft;
    if (draft == null) return;
    emit(EditGoalState.editing(draft.copyWith(targetDate: value)));
  }

  Future<void> submit() async {
    final draft = _draft;
    if (draft == null || !draft.canSubmit) return;
    emit(EditGoalState.submitting(draft));

    final result = await _updateGoal(
      UpdateGoalParams(
        goalId: draft.id!,
        name: draft.name,
        target: draft.target,
        targetDate: draft.targetDate!,
      ),
    );

    emit(
      result.fold(
        (failure) => EditGoalState.editing(draft, error: _toMessage(failure)),
        (_) => EditGoalState.done(draft),
      ),
    );
  }
}
