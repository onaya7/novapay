import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';

void main() {
  group('AppThemeColors', () {
    test('light pins every role', () {
      const colors = AppThemeColors.light;
      expect(colors.primary, const Color(0xFF1174ED));
      expect(colors.primaryStrong, const Color(0xFF0E5FC4));
      expect(colors.background, const Color(0xFFFAF9F6));
      expect(colors.cards, const Color(0xFFFFFFFF));
      expect(colors.fill, const Color(0xFFF3F5F7));
      expect(colors.divider, const Color(0xFFF3F5F7));
      expect(colors.textHeading, const Color(0xFF000000));
      expect(colors.textSubheading, const Color(0xFF4A4A49));
      expect(colors.subtext, const Color(0xFF686766));
      expect(colors.warning, const Color(0xFFFF8F00));
    });

    test('dark pins every role', () {
      const colors = AppThemeColors.dark;
      expect(colors.primary, const Color(0xFF1174ED));
      expect(colors.primaryStrong, const Color(0xFF0E5FC4));
      expect(colors.background, const Color(0xFF1F1F1F));
      expect(colors.cards, const Color(0xFF292929));
      expect(colors.fill, const Color(0xFF3D3F47));
      expect(colors.divider, const Color(0xFF3D3F47));
      expect(colors.textHeading, const Color(0xFFFFFFFF));
      expect(colors.textSubheading, const Color(0xFFA9A9A9));
      expect(colors.subtext, const Color(0xFF8F8F8F));
      expect(colors.warning, const Color(0xFFFFB300));
    });

    test('copyWith replaces only what it is given', () {
      const original = AppThemeColors.light;
      const other = Color(0xFF000001);

      final recolored = original.copyWith(background: other);
      expect(recolored.background, other);
      expect(recolored.primary, original.primary);

      final rebranded = original.copyWith(primary: other);
      expect(rebranded.primary, other);
      expect(rebranded.background, original.background);
    });

    test('copyWith with every role set takes all of them', () {
      const replacement = AppThemeColors.dark;
      final changed = AppThemeColors.light.copyWith(
        primary: replacement.primary,
        primaryStrong: replacement.primaryStrong,
        background: replacement.background,
        cards: replacement.cards,
        fill: replacement.fill,
        divider: replacement.divider,
        textHeading: replacement.textHeading,
        textSubheading: replacement.textSubheading,
        subtext: replacement.subtext,
        warning: replacement.warning,
      );

      expect(changed.background, replacement.background);
      expect(changed.textHeading, replacement.textHeading);
      expect(changed.warning, replacement.warning);
    });

    test('lerp at 1 lands on the other end', () {
      final blended = AppThemeColors.light.lerp(AppThemeColors.dark, 1);

      expect(blended.background, AppThemeColors.dark.background);
      expect(blended.textHeading, AppThemeColors.dark.textHeading);
      expect(blended.subtext, AppThemeColors.dark.subtext);
    });

    test('lerp against a foreign extension keeps this one', () {
      final blended = AppThemeColors.light.lerp(null, 0.5);

      expect(blended, same(AppThemeColors.light));
    });

    testWidgets('of and the context getters read the theme', (tester) async {
      late AppThemeColors fromOf;
      late AppThemeColors fromGetter;
      late TextTheme texts;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              fromOf = AppThemeColors.of(context);
              fromGetter = context.colors;
              texts = context.texts;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(fromOf, AppThemeColors.light);
      expect(fromGetter, same(fromOf));
      expect(texts.bodyMedium?.fontSize, 14);
    });
  });
}
