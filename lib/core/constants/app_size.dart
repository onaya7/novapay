import 'package:material_ui/material_ui.dart';

/// Spacing, radius, icon and touch-target values, all on a 4pt rhythm.
abstract class AppSize {
  static const double xs = 4;
  static const double sm = 8;
  static const double smd = 12;
  static const double md = 16;
  static const double mdl = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
  static const double huge = 64;

  static const double radiusSm = 10;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusPill = 100;

  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  static const double touchTarget = 44;

  /// Minimums, not fixed heights: the system font scale grows them.
  static const double buttonMinHeight = 56;
  static const double inputMinHeight = 52;
  static const double rowMinHeight = 66;

  /// The one raised surface: the balance card. Everything else is flat.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 25),
  ];

  static SizedBox w(double? width) => SizedBox(width: width);

  static SizedBox h(double? height) => SizedBox(height: height);
}
