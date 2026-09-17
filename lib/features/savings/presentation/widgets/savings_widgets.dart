import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/money_text.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/components/status_chip.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/l10n/l10n.dart';

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
  const new({
    required this.goal,
    required this.onTap,
    required this.onMore,
    super.key,
  });

  final SavingsGoalItem goal;
  final VoidCallback onTap;
  final VoidCallback onMore;

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
                    StatusChip(
                      label: context.l10n.goalReachedLabel,
                      tone: ChipTone.success,
                    )
                  else if (goal.hasPending)
                    StatusChip(
                      label: context.l10n.pendingLabel,
                      tone: ChipTone.pending,
                    ),
                  _MoreButton(onTap: onMore),
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

/// The overflow tap target on a goal card: edit or delete.
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Tooltip(
      message: context.l10n.moreActionsTooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.radiusPill),
          child: SizedBox(
            height: AppSize.touchTarget,
            width: AppSize.touchTarget,
            child: Icon(Icons.more_vert, color: colors.subtext),
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
                context.l10n.savedSoFarLabel,
                style: texts.bodySmall?.copyWith(color: colors.textSubheading),
              ),
              const Spacer(),
              MoneyText(
                amount: goal.saved,
                label: context.l10n.savedSoFarLabel,
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

/// What a goal card's overflow menu can be asked for.
enum GoalAction { edit, delete }

/// The overflow menu for a goal card: edit or delete it.
class GoalActionsSheet extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSize.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            _ActionTile(
              icon: Icons.edit_outlined,
              label: l10n.editGoalTitle,
              onTap: () => Navigator.of(context).pop(GoalAction.edit),
            ),
            _ActionTile(
              icon: Icons.delete_outline,
              label: l10n.deleteGoalButton,
              isDestructive: true,
              onTap: () => Navigator.of(context).pop(GoalAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirms before a goal is removed for good.
class DeleteGoalConfirmSheet extends StatelessWidget {
  const new({required this.goalName, super.key});

  final String goalName;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSize.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            Text(
              l10n.deleteGoalConfirmTitle(goalName),
              style: texts.titleLarge,
            ),
            AppSize.h(AppSize.sm),
            Text(
              l10n.deleteGoalConfirmBody,
              style: texts.bodyMedium?.copyWith(color: colors.subtext),
            ),
            AppSize.h(AppSize.lg),
            CustomButton(
              label: l10n.deleteGoalButton,
              variant: ButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            AppSize.h(AppSize.sm),
            CustomButton(
              label: l10n.keepGoalButton,
              variant: ButtonVariant.plain,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppSize.md),
        decoration: BoxDecoration(
          color: colors.border,
          borderRadius: BorderRadius.circular(AppSize.radiusPill),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final color = isDestructive ? AppColor.danger : colors.textHeading;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSize.sm),
          child: Row(
            children: [
              Icon(icon, color: color),
              AppSize.w(AppSize.smd),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tap-to-pick date field, styled like the app's other inputs. The picker
/// itself is adaptive: a Cupertino wheel on iOS/macOS, Material's calendar
/// elsewhere, since material_ui has no single picker that switches itself.
class GoalDateField extends StatelessWidget {
  const new({
    required this.value,
    required this.onChanged,
    this.label,
    super.key,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final chosen = value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? l10n.targetDateLabel,
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
                      chosen == null ? l10n.chooseDateHint : _format(chosen),
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
    final initialDate = value ?? now.add(const Duration(days: 30));
    // A savings target is always ahead; the default last date is today,
    // which would block every valid choice.
    final firstDate = now;
    final lastDate = DateTime(now.year + 10, now.month, now.day);
    final isCupertino = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

    final picked = isCupertino
        ? await _pickCupertino(context, initialDate, firstDate, lastDate)
        : await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
          );
    if (picked != null) onChanged(picked);
  }

  Future<DateTime?> _pickCupertino(
    BuildContext context,
    DateTime initialDate,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    final l10n = context.l10n;
    var selected = initialDate;
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (sheetContext) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(sheetContext),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l10n.cancelButton),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.of(sheetContext).pop(selected),
                  child: Text(l10n.doneButton),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (value) => selected = value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
