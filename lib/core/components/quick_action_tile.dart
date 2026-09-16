import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/constants/app_size.dart';

/// An icon tile with its label beneath. A null [onTap] reads as unavailable
/// rather than being hidden, so the set of actions stays stable.
class QuickActionTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        // The label is inside the ink, so the tap target is the whole tile
        // rather than just the icon.
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSize.radiusLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.cards,
                    borderRadius: BorderRadius.circular(AppSize.radiusLg),
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    icon,
                    size: AppSize.iconLg,
                    color: enabled ? colors.primary : colors.subtext,
                  ),
                ),
                AppSize.h(AppSize.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: enabled ? colors.textSubheading : colors.subtext,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The row of primary actions under the balance card.
class QuickActionRow extends StatelessWidget {
  const new({required this.tiles, super.key});

  final List<QuickActionTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tile in tiles) ...[
          if (tile != tiles.first) AppSize.w(AppSize.smd),
          Expanded(child: tile),
        ],
      ],
    );
  }
}
