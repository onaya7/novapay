import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/savings/domain/entities/contribution_draft.dart';
import 'package:novapay/features/savings/domain/entities/goal_draft.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';

SavingsGoalItem _goal({
  int targetKobo = 10000000,
  int savedKobo = 2500000,
  int pendingKobo = 0,
  int daysAhead = 30,
}) => SavingsGoalItem(
  id: 'g1',
  name: 'Rent',
  targetKobo: targetKobo,
  savedKobo: savedKobo,
  pendingKobo: pendingKobo,
  targetDate: DateTime.now().add(Duration(days: daysAhead)),
);

void main() {
  group('SavingsGoalItem', () {
    test('progress counts queued money, so the bar moves at once', () {
      final goal = _goal(pendingKobo: 2500000);

      expect(goal.saved, const Money.fromKobo(2500000));
      expect(goal.pending, const Money.fromKobo(2500000));
      expect(goal.projected, const Money.fromKobo(5000000));
      expect(goal.percentComplete, 50);
      expect(goal.settledFraction, 0.25);
      expect(goal.progressFraction, 0.5);
    });

    test('percent is truncated, so 99.99% never reads as complete', () {
      final goal = _goal(targetKobo: 10000, savedKobo: 9999);

      expect(goal.percentComplete, 99);
      expect(goal.isComplete, isFalse);
    });

    test('remaining never goes below zero', () {
      expect(_goal(savedKobo: 99999999).remaining, Money.zero);
    });

    test('reaching the target completes it, queued money included', () {
      expect(_goal(savedKobo: 10000000).isComplete, isTrue);
      expect(
        _goal(savedKobo: 5000000, pendingKobo: 5000000).isComplete,
        isTrue,
      );
      expect(_goal().isComplete, isFalse);
    });

    test('a zero target cannot divide by zero', () {
      final goal = _goal(targetKobo: 0, savedKobo: 0);

      expect(goal.percentComplete, 0);
      expect(goal.progressFraction, 0);
    });

    test('the due label counts down, then says the date passed', () {
      expect(_goal().dueLabel, 'Due in 30 days');
      expect(_goal(daysAhead: 1).dueLabel, 'Due tomorrow');
      expect(_goal(daysAhead: 0).dueLabel, 'Due today');
      expect(_goal(daysAhead: -3).dueLabel, 'Target date passed');
    });

    test('a reached goal says so rather than counting down', () {
      final goal = _goal(savedKobo: 10000000, daysAhead: -3);

      expect(goal.dueLabel, 'Goal reached');
      expect(goal.isOverdue, isFalse);
    });

    test('only an unmet goal past its date is overdue', () {
      expect(_goal(daysAhead: -1).isOverdue, isTrue);
      expect(_goal(daysAhead: 1).isOverdue, isFalse);
    });
  });

  group('GoalDraft', () {
    test('a fresh draft cannot be submitted', () {
      const draft = GoalDraft();

      expect(draft.nameIsValid, isFalse);
      expect(draft.targetIsValid, isFalse);
      expect(draft.dateIsValid, isFalse);
      expect(draft.canSubmit, isFalse);
    });

    test('whitespace is not a name', () {
      expect(const GoalDraft(name: '   ').nameIsValid, isFalse);
      expect(const GoalDraft(name: 'Rent').nameIsValid, isTrue);
    });

    test('a zero target is not a target', () {
      expect(const GoalDraft().targetIsValid, isFalse);
      expect(const GoalDraft(target: Money.fromKobo(1)).targetIsValid, isTrue);
    });

    test('all three are needed before it can be created', () {
      final complete = GoalDraft(
        name: 'Rent',
        target: const Money.fromKobo(100),
        targetDate: DateTime(2027),
      );

      expect(complete.canSubmit, isTrue);
      expect(complete.copyWith(name: '').canSubmit, isFalse);
      expect(complete.copyWith(target: Money.zero).canSubmit, isFalse);
      expect(const GoalDraft(name: 'Rent').canSubmit, isFalse);
    });
  });

  group('ContributionDraft', () {
    final draft = ContributionDraft(
      goal: _goal(),
      available: const Money.fromKobo(2000000),
    );

    test('nothing entered cannot be submitted', () {
      expect(draft.amountIsEntered, isFalse);
      expect(draft.canSubmit, isFalse);
    });

    test('enough is measured against available, edge included', () {
      expect(
        draft.copyWith(amount: const Money.fromKobo(2000000)).hasEnough,
        isTrue,
      );
      expect(
        draft.copyWith(amount: const Money.fromKobo(2000001)).hasEnough,
        isFalse,
      );
    });

    test('an affordable amount can be submitted', () {
      final ready = draft.copyWith(amount: const Money.fromKobo(500000));

      expect(ready.canSubmit, isTrue);
      expect(ready.remaining, const Money.fromKobo(1500000));
      expect(ready.projected, const Money.fromKobo(3000000));
    });

    test('too much is blocked even though an amount is entered', () {
      final over = draft.copyWith(amount: const Money.fromKobo(9999999));

      expect(over.amountIsEntered, isTrue);
      expect(over.canSubmit, isFalse);
    });
  });
}
