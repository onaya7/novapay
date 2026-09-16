import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/gen/fonts.gen.dart';

/// The type scale. `bodyMedium` at 14/22 is the default body style.
abstract class TTextTheme {
  /// Declared in `pubspec.yaml`; the files are licensed under OFL-1.1.
  static const String fontFamily = FontFamily.plusJakartaSans;

  static const FontWeight _regular = FontWeight.w500;
  static const FontWeight _bold = FontWeight.w700;

  static final TextTheme light = _theme(AppThemeColors.light);

  static final TextTheme dark = _theme(AppThemeColors.dark);

  static TextTheme _theme(AppThemeColors colors) => TextTheme(
    displayLarge: _style(44, 52, _bold, colors.textHeading),
    displayMedium: _style(32, 40, _bold, colors.textHeading),
    headlineMedium: _style(24, 32, _bold, colors.textHeading),
    titleLarge: _style(20, 28, _bold, colors.textHeading),
    titleMedium: _style(16, 24, _bold, colors.textHeading),
    bodyLarge: _style(16, 24, _regular, colors.textHeading),
    bodyMedium: _style(14, 22, _regular, colors.textHeading),
    bodySmall: _style(12, 20, _regular, colors.textSubheading),
    labelLarge: _style(14, 20, _bold, colors.textHeading),
    labelMedium: _style(12, 16, _bold, colors.textSubheading),
    labelSmall: _style(10, 14, _bold, colors.subtext, spacing: 0.5),
  );

  static TextStyle _style(
    double size,
    double lineHeight,
    FontWeight weight,
    Color color, {
    double spacing = 0,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: spacing,
    color: color,
  );
}
