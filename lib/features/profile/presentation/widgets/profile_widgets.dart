import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/presentation/cubit/locale_cubit.dart';
import 'package:novapay/app/presentation/cubit/theme_cubit.dart';
import 'package:novapay/app/view/app.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/l10n/l10n.dart';

/// A labelled row in a settings group.
class SettingsRow extends StatelessWidget {
  const new({
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final detail = value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSize.smd),
          child: Row(
            children: [
              Expanded(child: Text(label, style: texts.bodyLarge)),
              if (detail != null)
                Text(
                  detail,
                  style: texts.bodyMedium?.copyWith(color: colors.subtext),
                ),
              ?trailing,
              if (onTap != null) ...[
                AppSize.w(AppSize.sm),
                Icon(
                  Icons.chevron_right,
                  size: AppSize.iconMd,
                  color: colors.subtext,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A card that groups settings rows under a heading.
class SettingsGroup extends StatelessWidget {
  const new({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colors.textSubheading),
        ),
        AppSize.h(AppSize.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSize.md),
          decoration: BoxDecoration(
            color: colors.cards,
            borderRadius: BorderRadius.circular(AppSize.radiusXl),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Light, dark, or follow the device.
class ThemeModeToggle extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ThemeCubit, AppThemeMode>(
      builder: (context, mode) => SegmentedButton<AppThemeMode>(
        showSelectedIcon: false,
        segments: [
          for (final option in AppThemeMode.values)
            ButtonSegment<AppThemeMode>(
              value: option,
              label: Text(option.label(l10n)),
            ),
        ],
        selected: {mode},
        onSelectionChanged: (selection) =>
            context.read<ThemeCubit>().setMode(selection.single),
      ),
    );
  }
}

/// English, Spanish, French, or follow the device.
class LocaleToggle extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<LocaleCubit, AppLocale>(
      builder: (context, locale) => SegmentedButton<AppLocale>(
        showSelectedIcon: false,
        segments: [
          for (final option in AppLocale.values)
            ButtonSegment<AppLocale>(
              value: option,
              label: Text(option.label(l10n)),
            ),
        ],
        selected: {locale},
        onSelectionChanged: (selection) =>
            context.read<LocaleCubit>().setLocale(selection.single),
      ),
    );
  }
}
