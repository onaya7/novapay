import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/config/theme/custom_theme/text_theme.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';

abstract class AppTheme {
  static final ThemeData light = _build(
    AppThemeColors.light,
    Brightness.light,
    TTextTheme.light,
  );

  static final ThemeData dark = _build(
    AppThemeColors.dark,
    Brightness.dark,
    TTextTheme.dark,
  );

  static ThemeData _build(
    AppThemeColors colors,
    Brightness brightness,
    TextTheme textTheme,
  ) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: TTextTheme.fontFamily,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColor.brand,
            brightness: brightness,
          ).copyWith(
            primary: colors.primary,
            onPrimary: AppColor.onBrand,
            surface: colors.cards,
            onSurface: colors.textHeading,
            error: AppColor.danger,
          ),
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textHeading,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.cards,
        constraints: const BoxConstraints(minHeight: AppSize.inputMinHeight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSize.md,
          vertical: AppSize.smd,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.subtext),
        border: _border(colors.border),
        enabledBorder: _border(colors.border),
        focusedBorder: _border(colors.primary, width: 1.5),
        errorBorder: _border(AppColor.danger),
        focusedErrorBorder: _border(AppColor.danger, width: 1.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.fill,
      ),
      extensions: [colors],
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSize.radiusMd),
        borderSide: BorderSide(color: color, width: width),
      );
}
