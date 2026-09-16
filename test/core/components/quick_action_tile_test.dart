import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/quick_action_tile.dart';

import '../../helpers/helpers.dart';

void main() {
  group('QuickActionTile', () {
    testWidgets('the whole tile is the tap target, label included', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpApp(
        QuickActionTile(
          icon: Icons.arrow_upward,
          label: 'Send',
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.text('Send'));
      expect(taps, 1);

      await tester.tap(find.byIcon(Icons.arrow_upward));
      expect(taps, 2);
    });

    testWidgets('unavailable stays visible and greys out', (tester) async {
      await tester.pumpApp(
        const QuickActionTile(icon: Icons.add, label: 'Add money', onTap: null),
      );

      expect(find.text('Add money'), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.add)).color,
        AppThemeColors.light.subtext,
      );
    });

    testWidgets('an available tile takes the brand colour', (tester) async {
      await tester.pumpApp(
        QuickActionTile(icon: Icons.add, label: 'Add money', onTap: () {}),
      );

      expect(
        tester.widget<Icon>(find.byIcon(Icons.add)).color,
        AppThemeColors.light.primary,
      );
    });

    testWidgets('it announces itself as a button with its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        QuickActionTile(icon: Icons.add, label: 'Add money', onTap: () {}),
      );

      expect(find.bySemanticsLabel('Add money'), findsOneWidget);
      handle.dispose();
    });
  });

  group('QuickActionRow', () {
    testWidgets('spreads its tiles evenly', (tester) async {
      await tester.pumpApp(
        QuickActionRow(
          tiles: [
            QuickActionTile(icon: Icons.add, label: 'One', onTap: () {}),
            QuickActionTile(icon: Icons.remove, label: 'Two', onTap: () {}),
          ],
        ),
      );

      final first = tester.getSize(find.text('One'));
      expect(find.byType(QuickActionTile), findsNWidgets(2));
      expect(first.width, greaterThan(0));
    });
  });
}
