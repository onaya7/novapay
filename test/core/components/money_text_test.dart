import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/components/money_text.dart';
import 'package:novapay/core/money/money.dart';

import '../../helpers/helpers.dart';

void main() {
  group('MoneyText', () {
    testWidgets('announces words and hides the digits from semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        MoneyText(amount: Money.parse('2480'), label: 'Balance'),
      );

      expect(find.text('₦2,480.00'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Balance, two thousand four hundred and eighty naira',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('drops the label when there is none', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(MoneyText(amount: Money.parse('5')));

      expect(find.bySemanticsLabel('five naira'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('signs a credit but leaves a debit to its own minus', (
      tester,
    ) async {
      await tester.pumpApp(MoneyText(amount: Money.parse('500'), signed: true));
      expect(find.text('+₦500.00'), findsOneWidget);

      await tester.pumpApp(
        MoneyText(amount: Money.parse('-500'), signed: true),
      );
      expect(find.text('-₦500.00'), findsOneWidget);
    });
  });
}
