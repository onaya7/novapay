import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/constants/app_size.dart';

/// A section title, with an optional action on the right.
class SectionHeader extends StatelessWidget {
  const new({required this.title, this.actionLabel, this.onAction, super.key});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        if (label != null)
          CustomButton(
            label: label,
            onPressed: onAction,
            variant: ButtonVariant.text,
            expand: false,
          ),
      ],
    );
  }
}

/// A brand-tinted circle carrying an icon, for a surface with no photo.
class AppAvatar extends StatelessWidget {
  const new({required this.icon, this.size = 44, super.key});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.brandSubtle,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: AppSize.iconMd, color: colors.primaryStrong),
    );
  }
}
