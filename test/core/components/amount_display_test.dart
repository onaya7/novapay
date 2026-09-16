import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/amount_display.dart';
import 'package:novapay/core/money/money.dart';

import '../../helpers/helpers.dart';

const _fiveThousand = Money.fromKobo(500000);
const _tenThousand = Money.fromKobo(1000000);

Color _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  group('AmountDisplay', () {
    testWidgets('shows the figure and announces it as words', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const AmountDisplay(amount: _fiveThousand, label: 'Sending'),
      );

      expect(find.text('₦5,000.00'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Sending, five thousand naira'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('an unentered amount is greyed, not black', (tester) async {
      await tester.pumpApp(
        const AmountDisplay(amount: Money.zero, label: 'Sending'),
      );

      expect(_textColor(tester, '₦0.00'), AppThemeColors.light.subtext);
    });

    testWidgets('an entered amount takes the heading colour', (tester) async {
      await tester.pumpApp(
        const AmountDisplay(amount: _fiveThousand, label: 'Sending'),
      );

      expect(_textColor(tester, '₦5,000.00'), AppThemeColors.light.textHeading);
    });

    testWidgets('the helper turns to warning when it is a problem', (
      tester,
    ) async {
      await tester.pumpApp(
        const AmountDisplay(
          amount: _fiveThousand,
          label: 'Sending',
          helper: 'More than you have',
          hasError: true,
        ),
      );

      expect(
        _textColor(tester, 'More than you have'),
        AppThemeColors.light.warning,
      );
    });

    testWidgets('no helper means no second line', (tester) async {
      await tester.pumpApp(
        const AmountDisplay(amount: _fiveThousand, label: 'Sending'),
      );

      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('QuickAmountChips', () {
    testWidgets('a tap reports the amount it carries', (tester) async {
      Money? chosen;
      await tester.pumpApp(
        QuickAmountChips(
          amounts: const [_fiveThousand, _tenThousand],
          selected: null,
          onSelected: (amount) => chosen = amount,
        ),
      );

      await tester.tap(find.text('₦10,000.00'));
      expect(chosen, _tenThousand);
    });

    testWidgets('the chosen chip is marked for a screen reader too', (
      tester,
    ) async {
      await tester.pumpApp(
        QuickAmountChips(
          amounts: const [_fiveThousand, _tenThousand],
          selected: _fiveThousand,
          onSelected: (_) {},
        ),
      );

      final chips = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.button ?? false)
          .toList();

      expect(chips, hasLength(2));
      expect(chips.first.properties.selected, isTrue);
      expect(chips.last.properties.selected, isFalse);
    });

    testWidgets('the chosen chip takes the brand tint', (tester) async {
      await tester.pumpApp(
        QuickAmountChips(
          amounts: const [_fiveThousand, _tenThousand],
          selected: _fiveThousand,
          onSelected: (_) {},
        ),
      );

      final materials = tester
          .widgetList<Material>(find.byType(Material))
          .where((m) => m.color != null)
          .toList();
      expect(
        materials.map((m) => m.color),
        contains(AppThemeColors.light.brandSubtle),
      );
    });
  });
}
