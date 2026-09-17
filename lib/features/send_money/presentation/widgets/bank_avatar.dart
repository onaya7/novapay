import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/extensions/string_extension.dart';
import 'package:novapay/features/send_money/domain/entities/bank.dart';

/// A bank's logo, or its initials on a brand tint when none is bundled.
class BankAvatar extends StatelessWidget {
  const new({required this.bank, this.size = 36, super.key});

  final Bank bank;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final logo = bank.logoAsset;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: logo == null
            ? ColoredBox(
                color: colors.brandSubtle,
                child: Center(
                  child: Text(
                    bank.name.initials,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: colors.primaryStrong),
                  ),
                ),
              )
            : Image.asset(logo, fit: BoxFit.cover),
      ),
    );
  }
}
