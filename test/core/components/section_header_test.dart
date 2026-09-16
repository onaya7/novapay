import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/section_header.dart';

import '../../helpers/helpers.dart';

void main() {
  group('SectionHeader', () {
    testWidgets('a plain header is just its title', (tester) async {
      await tester.pumpApp(const SectionHeader(title: 'Activity'));

      expect(find.text('Activity'), findsOneWidget);
      expect(find.byType(CustomButton), findsNothing);
    });

    testWidgets('an action sits on the right and fires', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        SectionHeader(
          title: 'Activity',
          actionLabel: 'See all',
          onAction: () => taps++,
        ),
      );

      expect(find.text('See all'), findsOneWidget);
      await tester.tap(find.text('See all'));
      expect(taps, 1);
    });

    testWidgets('an action with no callback renders dead', (tester) async {
      await tester.pumpApp(
        const SectionHeader(title: 'Activity', actionLabel: 'See all'),
      );

      expect(
        tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
        isNull,
      );
    });
  });

  group('AppAvatar', () {
    testWidgets('carries an icon on the brand tint', (tester) async {
      await tester.pumpApp(const AppAvatar(icon: Icons.wallet));

      expect(find.byIcon(Icons.wallet), findsOneWidget);
      final box = tester.widget<Container>(find.byType(Container));
      expect(
        (box.decoration! as BoxDecoration).color,
        AppThemeColors.light.brandSubtle,
      );
    });

    testWidgets('sizes to what it is given', (tester) async {
      await tester.pumpApp(
        const Center(child: AppAvatar(icon: Icons.wallet, size: 64)),
      );

      expect(tester.getSize(find.byType(Container)), const Size(64, 64));
    });
  });
}
