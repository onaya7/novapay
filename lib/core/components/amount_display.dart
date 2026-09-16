import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/money_text.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/money/money.dart';

/// The amount being entered, shown at display size with a line of context
/// beneath it. The figure is the screen's subject, so it is not a form field.
class AmountDisplay extends StatelessWidget {
  const new({
    required this.amount,
    required this.label,
    this.helper,
    this.hasError = false,
    super.key,
  });

  final Money amount;

  /// Prepended to the spoken form, since the figure carries no visible label.
  final String label;
  final String? helper;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final note = helper;

    return Column(
      children: [
        MoneyText(
          amount: amount,
          label: label,
          style: texts.displayLarge?.copyWith(
            color: amount.isZero ? colors.subtext : colors.textHeading,
          ),
        ),
        if (note != null) ...[
          AppSize.h(AppSize.sm),
          Text(
            note,
            textAlign: TextAlign.center,
            style: texts.bodySmall?.copyWith(
              color: hasError ? colors.warning : colors.subtext,
            ),
          ),
        ],
      ],
    );
  }
}

/// Preset amounts, so the common cases are one tap rather than typing.
class QuickAmountChips extends StatelessWidget {
  const new({
    required this.amounts,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<Money> amounts;
  final Money? selected;
  final ValueChanged<Money> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final amount in amounts) ...[
          if (amount != amounts.first) AppSize.w(AppSize.smd),
          Expanded(
            child: _Chip(
              label: amount.format(),
              isSelected: amount == selected,
              onTap: () => onSelected(amount),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? colors.brandSubtle : colors.cards,
        borderRadius: BorderRadius.circular(AppSize.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.radiusPill),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.radiusPill),
              border: Border.all(
                color: isSelected ? colors.primary : colors.border,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? colors.primaryStrong : colors.textHeading,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
