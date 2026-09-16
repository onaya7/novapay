import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/summary_card.dart';

import '../../helpers/helpers.dart';

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  group('SummaryRow', () {
    testWidgets('puts the label left and the value right', (tester) async {
      await tester.pumpApp(
        const SummaryRow(label: 'Amount', value: '₦5,000.00'),
      );

      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('₦5,000.00'), findsOneWidget);
      expect(
        tester.getCenter(find.text('Amount')).dx,
        lessThan(tester.getCenter(find.text('₦5,000.00')).dx),
      );
    });

    testWidgets('an ordinary label is secondary, not heading', (tester) async {
      await tester.pumpApp(
        const SummaryRow(label: 'Amount', value: '₦5,000.00'),
      );

      expect(
        _styleOf(tester, 'Amount').color,
        AppThemeColors.light.textSubheading,
      );
    });

    testWidgets('the emphasised row is heavier on both sides', (tester) async {
      await tester.pumpApp(
        const SummaryRow(
          label: 'You send',
          value: '₦5,000.00',
          emphasised: true,
        ),
      );

      expect(_styleOf(tester, 'You send').fontWeight, FontWeight.w700);
      expect(_styleOf(tester, '₦5,000.00').fontSize, 16);
    });
  });

  group('SummaryCard', () {
    testWidgets('stacks its rows on a surface', (tester) async {
      await tester.pumpApp(
        const SummaryCard(
          children: [
            SummaryRow(label: 'Fee', value: 'No fee'),
            SummaryRow(label: 'Amount', value: '₦5,000.00'),
          ],
        ),
      );

      expect(find.byType(SummaryRow), findsNWidgets(2));
      final card = tester.widget<Container>(find.byType(Container).first);
      expect(
        (card.decoration! as BoxDecoration).color,
        AppThemeColors.light.cards,
      );
    });

    testWidgets('a single row gets no leading gap', (tester) async {
      await tester.pumpApp(
        const SummaryCard(
          children: [SummaryRow(label: 'Fee', value: 'No fee')],
        ),
      );

      expect(find.byType(SummaryRow), findsOneWidget);
    });
  });
}
