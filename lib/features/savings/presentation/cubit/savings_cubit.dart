import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/domain/usecases/savings_usecases.dart';

part 'savings_cubit.freezed.dart';
part 'savings_state.dart';

@injectable
class SavingsCubit extends Cubit<SavingsState> {
  SavingsCubit(this._load, this._watch, this._delete)
    : super(const SavingsState.loading());

  final LoadGoals _load;
  final WatchGoals _watch;
  final DeleteGoal _delete;

  static const ConvertFailureToString _toMessage = ConvertFailureToString();

  StreamSubscription<List<SavingsGoalItem>>? _subscription;

  /// Loads once, then follows the queue so a contribution shows immediately.
  Future<void> start() async {
    await refresh();
    _subscription ??= _watch(const NoParams()).listen(_onGoals);
  }

  Future<void> refresh() async {
    final result = await _load(const NoParams());
    emit(
      result.fold(
        (failure) => SavingsState.failure(_toMessage(failure)),
        SavingsState.ready,
      ),
    );
  }

  void _onGoals(List<SavingsGoalItem> goals) {
    emit(SavingsState.ready(goals));
  }

  Future<void> delete(String goalId) async {
    final result = await _delete(DeleteGoalParams(goalId: goalId));
    final failure = result.fold((failure) => failure, (_) => null);
    if (failure == null) {
      await refresh();
      return;
    }
    emit(SavingsState.failure(_toMessage(failure)));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
