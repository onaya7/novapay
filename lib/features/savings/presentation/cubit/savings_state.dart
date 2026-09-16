part of 'savings_cubit.dart';

@freezed
sealed class SavingsState with _$SavingsState {
  const factory SavingsState.loading() = SavingsLoading;
  const factory SavingsState.ready(List<SavingsGoalItem> goals) = SavingsReady;
  const factory SavingsState.failure(String message) = SavingsFailure;
}
