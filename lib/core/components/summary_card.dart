import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/constants/app_size.dart';

/// A label and its value on one line, wrapping rather than truncating.
class SummaryRow extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    this.emphasised = false,
    super.key,
  });

  final String label;
  final String value;

  /// The line that answers the question the screen is asking.
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: emphasised
              ? texts.labelLarge
              : texts.bodyMedium?.copyWith(color: colors.textSubheading),
        ),
        AppSize.w(AppSize.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: emphasised ? texts.titleMedium : texts.labelLarge,
          ),
        ),
      ],
    );
  }
}

/// The white card that carries [SummaryRow]s, used wherever the app has to
/// show a set of facts before or after money moves.
class SummaryCard extends StatelessWidget {
  const new({required this.children, this.padding, super.key});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSize.mdl),
      decoration: BoxDecoration(
        color: colors.cards,
        borderRadius: BorderRadius.circular(AppSize.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) AppSize.h(AppSize.smd),
            children[i],
          ],
        ],
      ),
    );
  }
}
