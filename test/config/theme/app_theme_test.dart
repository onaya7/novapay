import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';

void main() {
  group('AppTheme', () {
    test('light carries its roles and paints the canvas', () {
      final theme = AppTheme.light;

      expect(theme.brightness, Brightness.light);
      expect(theme.extension<AppThemeColors>(), AppThemeColors.light);
      expect(theme.scaffoldBackgroundColor, AppThemeColors.light.background);
      expect(theme.colorScheme.primary, AppThemeColors.light.primary);
    });

    test('dark carries its roles and paints the canvas', () {
      final theme = AppTheme.dark;

      expect(theme.brightness, Brightness.dark);
      expect(theme.extension<AppThemeColors>(), AppThemeColors.dark);
      expect(theme.scaffoldBackgroundColor, AppThemeColors.dark.background);
      expect(
        theme.textTheme.bodyMedium?.color,
        AppThemeColors.dark.textHeading,
      );
    });

    test('body text is 14 on a 22 line box', () {
      final body = AppTheme.light.textTheme.bodyMedium!;

      expect(body.fontSize, 14);
      expect(body.height, 22 / 14);
    });

    test('no style drops below the 10px floor', () {
      final ramp = AppTheme.light.textTheme;
      final sizes = [
        ramp.displayMedium,
        ramp.headlineMedium,
        ramp.titleLarge,
        ramp.titleMedium,
        ramp.bodyLarge,
        ramp.bodyMedium,
        ramp.bodySmall,
        ramp.labelLarge,
        ramp.labelMedium,
        ramp.labelSmall,
      ].map((style) => style!.fontSize!);

      expect(sizes.every((size) => size >= 10), isTrue);
    });

    test('a field keeps a 52 minimum and a focused brand border', () {
      final input = AppTheme.light.inputDecorationTheme;
      final focused = input.focusedBorder! as OutlineInputBorder;

      expect(input.constraints?.minHeight, 52);
      expect(focused.borderSide.color, AppThemeColors.light.primary);
    });
  });
}
