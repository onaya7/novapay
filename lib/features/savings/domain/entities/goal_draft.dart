import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/money/money.dart';

part 'goal_draft.freezed.dart';

/// What the customer has filled in for a new goal, plus the rules that decide
/// whether it can be created. The screen asks this; no rule lives in a widget.
@freezed
abstract class GoalDraft with _$GoalDraft {
  const factory GoalDraft({
    @Default('') String name,
    @Default(Money.zero) Money target,
    DateTime? targetDate,
  }) = _GoalDraft;

  const GoalDraft._();

  bool get nameIsValid => name.trim().isNotEmpty;

  bool get targetIsValid => target.kobo > 0;

  bool get dateIsValid => targetDate != null;

  bool get canSubmit => nameIsValid && targetIsValid && dateIsValid;
}
