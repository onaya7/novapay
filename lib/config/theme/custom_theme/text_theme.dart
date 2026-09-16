import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';

/// The type scale. `bodyMedium` at 14/22 is the default body style.
abstract class TTextTheme {
  static final TextTheme light = _theme(AppThemeColors.light);

  static final TextTheme dark = _theme(AppThemeColors.dark);

  static TextTheme _theme(AppThemeColors colors) => TextTheme(
    displayMedium: _style(32, 40, FontWeight.w700, colors.textHeading),
    headlineMedium: _style(24, 32, FontWeight.w700, colors.textHeading),
    titleLarge: _style(20, 28, FontWeight.w600, colors.textHeading),
    titleMedium: _style(16, 24, FontWeight.w600, colors.textHeading),
    bodyLarge: _style(16, 24, FontWeight.w400, colors.textHeading),
    bodyMedium: _style(14, 22, FontWeight.w400, colors.textHeading),
    bodySmall: _style(12, 20, FontWeight.w400, colors.textSubheading),
    labelLarge: _style(14, 20, FontWeight.w600, colors.textHeading),
    labelMedium: _style(12, 16, FontWeight.w500, colors.textSubheading),
    labelSmall: _style(10, 14, FontWeight.w500, colors.subtext),
  );

  static TextStyle _style(
    double size,
    double lineHeight,
    FontWeight weight,
    Color color,
  ) => TextStyle(
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    color: color,
  );
}
