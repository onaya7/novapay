import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';

enum ChipTone { pending, success, danger }

/// Neutral pill with a colored dot; amber text on an amber fill is 1.27:1.
class StatusChip extends StatelessWidget {
  const new({required this.label, required this.tone, super.key});

  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSize.sm,
        vertical: AppSize.xs,
      ),
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: BorderRadius.circular(AppSize.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(
              color: _dot(colors),
              shape: BoxShape.circle,
            ),
          ),
          AppSize.w(AppSize.xs + 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: colors.textHeading),
          ),
        ],
      ),
    );
  }

  Color _dot(AppThemeColors colors) => switch (tone) {
    ChipTone.pending => colors.warning,
    ChipTone.success => AppColor.success,
    ChipTone.danger => AppColor.danger,
  };
}
