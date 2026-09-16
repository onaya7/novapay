import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/money_text.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/components/status_chip.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';

/// The bar, plus the percentage in words beside it. The percentage is computed
/// in integers; the fraction is one-way into the bar and never read back.
class GoalProgressBar extends StatelessWidget {
  const new({required this.goal, super.key});

  final SavingsGoalItem goal;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSize.radiusPill),
          child: Stack(
            children: [
              Container(height: 8, color: colors.fill),
              FractionallySizedBox(
                widthFactor: goal.progressFraction,
                child: Container(
                  height: 8,
                  color: goal.isComplete ? AppColor.success : colors.primary,
                ),
              ),
            ],
          ),
        ),
        AppSize.h(AppSize.sm),
        Row(
          children: [
            Text(
              '${goal.percentComplete}%',
              style: texts.labelMedium?.copyWith(color: colors.textSubheading),
            ),
            const Spacer(),
            Text(
              '${goal.projected.format()} of ${goal.target.format()}',
              style: texts.labelMedium?.copyWith(color: colors.textSubheading),
            ),
          ],
        ),
      ],
    );
  }
}

/// One goal in the list.
class GoalCard extends StatelessWidget {
  const new({required this.goal, required this.onTap, super.key});

  final SavingsGoalItem goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;

    return Material(
      color: colors.cards,
      borderRadius: BorderRadius.circular(AppSize.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSize.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.name, style: texts.titleMedium),
                        AppSize.h(AppSize.xs),
                        Text(
                          goal.dueLabel,
                          style: texts.bodySmall?.copyWith(
                            color: goal.isOverdue
                                ? colors.warning
                                : colors.subtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (goal.isComplete)
                    const StatusChip(label: 'Reached', tone: ChipTone.success)
                  else if (goal.hasPending)
                    const StatusChip(label: 'Pending', tone: ChipTone.pending),
                ],
              ),
              AppSize.h(AppSize.md),
              GoalProgressBar(goal: goal),
            ],
          ),
        ),
      ),
    );
  }
}

/// The header on the contribute screen: which goal, and where it stands.
class GoalSummaryHeader extends StatelessWidget {
  const new({required this.goal, super.key});

  final SavingsGoalItem goal;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSize.mdl),
      decoration: BoxDecoration(
        color: colors.cards,
        borderRadius: BorderRadius.circular(AppSize.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal.name, style: texts.titleMedium),
          AppSize.h(AppSize.xs),
          Row(
            children: [
              Text(
                'Saved so far',
                style: texts.bodySmall?.copyWith(color: colors.textSubheading),
              ),
              const Spacer(),
              MoneyText(
                amount: goal.saved,
                label: 'Saved so far',
                style: texts.labelLarge,
              ),
            ],
          ),
          AppSize.h(AppSize.md),
          GoalProgressBar(goal: goal),
        ],
      ),
    );
  }
}

/// Stands in for three goal cards while the first load runs.
class SavingsSkeleton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++) ...[
          const SkeletonBox(height: 132, radius: AppSize.radiusXl),
          AppSize.h(AppSize.smd),
        ],
      ],
    );
  }
}

/// A tap-to-pick date field, styled like the app's other inputs.
class GoalDateField extends StatelessWidget {
  const new({
    required this.value,
    required this.onChanged,
    this.label = 'Target date',
    super.key,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final chosen = value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: texts.labelLarge?.copyWith(color: colors.textSubheading),
        ),
        AppSize.h(AppSize.sm),
        Material(
          color: colors.cards,
          borderRadius: BorderRadius.circular(AppSize.radiusMd),
          child: InkWell(
            onTap: () => _pick(context),
            borderRadius: BorderRadius.circular(AppSize.radiusMd),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppSize.inputMinHeight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSize.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSize.radiusMd),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      chosen == null ? 'Choose a date' : _format(chosen),
                      style: texts.bodyLarge?.copyWith(
                        color: chosen == null
                            ? colors.subtext
                            : colors.textHeading,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: AppSize.iconMd,
                    color: colors.subtext,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _format(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now.add(const Duration(days: 30)),
      // A savings target is always ahead; the default last date is today,
      // which would block every valid choice.
      firstDate: now,
      lastDate: DateTime(now.year + 10, now.month, now.day),
    );
    if (picked != null) onChanged(picked);
  }
}
