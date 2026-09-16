import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/constants/app_color.dart';

/// The colors that change between light and dark; the rest sit on [AppColor].
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.primary,
    required this.primaryStrong,
    required this.background,
    required this.cards,
    required this.fill,
    required this.divider,
    required this.textHeading,
    required this.textSubheading,
    required this.subtext,
    required this.warning,
  });

  final Color primary;

  /// For anything below 24px on brand, where [primary] fails contrast.
  final Color primaryStrong;
  final Color background;
  final Color cards;

  /// Disabled fills and neutral pills; never a foreground.
  final Color fill;
  final Color divider;
  final Color textHeading;
  final Color textSubheading;
  final Color subtext;
  final Color warning;

  static const AppThemeColors light = AppThemeColors(
    primary: AppColor.brand,
    primaryStrong: AppColor.brandStrong,
    background: AppColor.canvasLight,
    cards: AppColor.surfaceLight,
    fill: AppColor.subtleLight,
    divider: AppColor.subtleLight,
    textHeading: AppColor.black,
    textSubheading: AppColor.textSecondaryLight,
    subtext: AppColor.textTertiaryLight,
    warning: AppColor.warningLight,
  );

  static const AppThemeColors dark = AppThemeColors(
    primary: AppColor.brand,
    primaryStrong: AppColor.brandStrong,
    background: AppColor.canvasDark,
    cards: AppColor.surfaceDark,
    fill: AppColor.subtleDark,
    divider: AppColor.subtleDark,
    textHeading: AppColor.white,
    textSubheading: AppColor.textSecondaryDark,
    subtext: AppColor.textTertiaryDark,
    warning: AppColor.warningDark,
  );

  static AppThemeColors of(BuildContext context) =>
      Theme.of(context).extension<AppThemeColors>()!;

  @override
  AppThemeColors copyWith({
    Color? primary,
    Color? primaryStrong,
    Color? background,
    Color? cards,
    Color? fill,
    Color? divider,
    Color? textHeading,
    Color? textSubheading,
    Color? subtext,
    Color? warning,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      background: background ?? this.background,
      cards: cards ?? this.cards,
      fill: fill ?? this.fill,
      divider: divider ?? this.divider,
      textHeading: textHeading ?? this.textHeading,
      textSubheading: textSubheading ?? this.textSubheading,
      subtext: subtext ?? this.subtext,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryStrong: Color.lerp(primaryStrong, other.primaryStrong, t)!,
      background: Color.lerp(background, other.background, t)!,
      cards: Color.lerp(cards, other.cards, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textHeading: Color.lerp(textHeading, other.textHeading, t)!,
      textSubheading: Color.lerp(textSubheading, other.textSubheading, t)!,
      subtext: Color.lerp(subtext, other.subtext, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppThemeColorsX on BuildContext {
  AppThemeColors get colors => AppThemeColors.of(this);

  TextTheme get texts => Theme.of(this).textTheme;
}
