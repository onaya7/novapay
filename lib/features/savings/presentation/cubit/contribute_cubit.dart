import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/savings/domain/entities/contribution_draft.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/domain/usecases/savings_usecases.dart';

part 'contribute_cubit.freezed.dart';
part 'contribute_state.dart';

@injectable
class ContributeCubit extends Cubit<ContributeState> {
  ContributeCubit(this._loadAvailable, this._contribute)
    : super(const ContributeState.initial());

  final LoadSavableBalance _loadAvailable;
  final ContributeToGoal _contribute;

  static const ConvertFailureToString _toMessage = ConvertFailureToString();

  Future<void> start(SavingsGoalItem goal) async {
    final result = await _loadAvailable(const NoParams());
    emit(
      result.fold(
        (failure) => ContributeState.editing(
          ContributionDraft(goal: goal),
          error: _toMessage(failure),
        ),
        (available) => ContributeState.editing(
          ContributionDraft(goal: goal, available: available),
        ),
      ),
    );
  }

  /// Parses through [Money], so a typed amount never becomes a double.
  void amountChanged(String value) {
    final draft = state.draft;
    if (draft == null) return;
    emit(
      ContributeState.editing(
        draft.copyWith(amount: Money.tryParse(value) ?? Money.zero),
      ),
    );
  }

  Future<void> submit() async {
    final draft = state.draft;
    if (draft == null || !draft.canSubmit) return;
    emit(ContributeState.submitting(draft));

    final result = await _contribute(
      ContributionParams(goalId: draft.goal.id, amount: draft.amount),
    );

    emit(
      result.fold(
        (failure) => ContributeState.editing(draft, error: _toMessage(failure)),
        (_) => ContributeState.done(draft),
      ),
    );
  }
}
