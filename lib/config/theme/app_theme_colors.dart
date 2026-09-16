import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/constants/app_color.dart';

/// The colors that change between light and dark; the rest sit on [AppColor].
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.primary,
    required this.primaryStrong,
    required this.brandSubtle,
    required this.background,
    required this.cards,
    required this.fill,
    required this.border,
    required this.divider,
    required this.textHeading,
    required this.textSubheading,
    required this.subtext,
    required this.warning,
    required this.successSurface,
  });

  final Color primary;

  /// Brand used as a foreground. It has to move between modes: the light value
  /// is 2.1:1 on a dark canvas.
  final Color primaryStrong;

  /// A brand-tinted surface, for an avatar, an icon tile or a chosen chip.
  final Color brandSubtle;
  final Color background;
  final Color cards;

  /// Disabled fills and neutral pills; never a foreground.
  final Color fill;

  /// Hairlines around a surface.
  final Color border;
  final Color divider;
  final Color textHeading;
  final Color textSubheading;
  final Color subtext;
  final Color warning;
  final Color successSurface;

  static const AppThemeColors light = AppThemeColors(
    primary: AppColor.brand,
    primaryStrong: AppColor.brandStrong,
    brandSubtle: AppColor.brandSubtleLight,
    background: AppColor.canvasLight,
    cards: AppColor.surfaceLight,
    fill: AppColor.subtleLight,
    border: AppColor.borderLight,
    divider: AppColor.borderLight,
    textHeading: AppColor.black,
    textSubheading: AppColor.textSecondaryLight,
    subtext: AppColor.textTertiaryLight,
    warning: AppColor.warningLight,
    successSurface: AppColor.successSurfaceLight,
  );

  static const AppThemeColors dark = AppThemeColors(
    primary: AppColor.brand,
    primaryStrong: AppColor.brandOnDark,
    brandSubtle: AppColor.brandSubtleDark,
    background: AppColor.canvasDark,
    cards: AppColor.surfaceDark,
    fill: AppColor.subtleDark,
    border: AppColor.borderDark,
    divider: AppColor.borderDark,
    textHeading: AppColor.white,
    textSubheading: AppColor.textSecondaryDark,
    subtext: AppColor.textTertiaryDark,
    warning: AppColor.warningDark,
    successSurface: AppColor.successSurfaceDark,
  );

  static AppThemeColors of(BuildContext context) =>
      Theme.of(context).extension<AppThemeColors>()!;

  @override
  AppThemeColors copyWith({
    Color? primary,
    Color? primaryStrong,
    Color? brandSubtle,
    Color? background,
    Color? cards,
    Color? fill,
    Color? border,
    Color? divider,
    Color? textHeading,
    Color? textSubheading,
    Color? subtext,
    Color? warning,
    Color? successSurface,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      brandSubtle: brandSubtle ?? this.brandSubtle,
      background: background ?? this.background,
      cards: cards ?? this.cards,
      fill: fill ?? this.fill,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textHeading: textHeading ?? this.textHeading,
      textSubheading: textSubheading ?? this.textSubheading,
      subtext: subtext ?? this.subtext,
      warning: warning ?? this.warning,
      successSurface: successSurface ?? this.successSurface,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryStrong: Color.lerp(primaryStrong, other.primaryStrong, t)!,
      brandSubtle: Color.lerp(brandSubtle, other.brandSubtle, t)!,
      background: Color.lerp(background, other.background, t)!,
      cards: Color.lerp(cards, other.cards, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textHeading: Color.lerp(textHeading, other.textHeading, t)!,
      textSubheading: Color.lerp(textSubheading, other.textSubheading, t)!,
      subtext: Color.lerp(subtext, other.subtext, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
    );
  }
}

extension AppThemeColorsX on BuildContext {
  AppThemeColors get colors => AppThemeColors.of(this);

  TextTheme get texts => Theme.of(this).textTheme;
}
