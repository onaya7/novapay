import 'package:material_ui/material_ui.dart';

/// Fixed values. Anything that changes with the theme belongs on
/// `AppThemeColors`.
abstract class AppColor {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color brand = Color(0xFF1174ED);
  static const Color brandStrong = Color(0xFF0E5FC4);

  /// White on brand is 4.43:1, so legal only at 24px, or 18.66px bold.
  static const Color onBrand = white;

  static const Color success = Color(0xFF08B142);
  static const Color danger = Color(0xFFFC2D2D);
  static const Color warningLight = Color(0xFFFF8F00);
  static const Color warningDark = Color(0xFFFFB300);

  static const Color canvasLight = Color(0xFFFAF9F6);
  static const Color canvasDark = Color(0xFF1F1F1F);
  static const Color surfaceLight = white;
  static const Color surfaceDark = Color(0xFF292929);
  static const Color subtleLight = Color(0xFFF3F5F7);
  static const Color subtleDark = Color(0xFF3D3F47);

  static const Color textSecondaryLight = Color(0xFF4A4A49);
  static const Color textSecondaryDark = Color(0xFFA9A9A9);
  static const Color textTertiaryLight = Color(0xFF686766);
  static const Color textTertiaryDark = Color(0xFF8F8F8F);

  static const Color scrim = Color(0x66000000);
}
