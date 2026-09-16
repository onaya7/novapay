import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/savings/domain/entities/goal_draft.dart';
import 'package:novapay/features/savings/domain/usecases/savings_usecases.dart';

part 'create_goal_cubit.freezed.dart';
part 'create_goal_state.dart';

@injectable
class CreateGoalCubit extends Cubit<CreateGoalState> {
  CreateGoalCubit(this._createGoal)
    : super(const CreateGoalState.editing(GoalDraft()));

  final CreateGoal _createGoal;

  static const ConvertFailureToString _toMessage = ConvertFailureToString();

  GoalDraft get _draft => state.draft;

  void nameChanged(String value) {
    emit(CreateGoalState.editing(_draft.copyWith(name: value)));
  }

  /// Parses through [Money], so a typed target never becomes a double.
  void targetChanged(String value) {
    emit(
      CreateGoalState.editing(
        _draft.copyWith(target: Money.tryParse(value) ?? Money.zero),
      ),
    );
  }

  void dateChanged(DateTime value) {
    emit(CreateGoalState.editing(_draft.copyWith(targetDate: value)));
  }

  Future<void> submit() async {
    final draft = _draft;
    if (!draft.canSubmit) return;
    emit(CreateGoalState.submitting(draft));

    final result = await _createGoal(
      NewGoalParams(
        name: draft.name,
        target: draft.target,
        targetDate: draft.targetDate!,
      ),
    );

    emit(
      result.fold(
        (failure) => CreateGoalState.editing(draft, error: _toMessage(failure)),
        (_) => CreateGoalState.done(draft),
      ),
    );
  }
}
