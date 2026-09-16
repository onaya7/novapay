import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';

part 'contribution_draft.freezed.dart';

/// An amount on its way into a goal, measured against what may be spent.
@freezed
abstract class ContributionDraft with _$ContributionDraft {
  const factory ContributionDraft({
    required SavingsGoalItem goal,
    @Default(Money.zero) Money amount,
    @Default(Money.zero) Money available,
  }) = _ContributionDraft;

  const ContributionDraft._();

  bool get amountIsEntered => amount.kobo > 0;

  /// Committed money is already gone, so this compares against available.
  bool get hasEnough => amount <= available;

  Money get remaining => available - amount;

  /// Saving more than the target is allowed; the goal simply completes.
  Money get projected => Money.fromKobo(goal.savedKobo + amount.kobo);

  bool get canSubmit => amountIsEntered && hasEnough;
}
