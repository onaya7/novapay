import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/components/custom_input_field.dart';

import '../../helpers/helpers.dart';

TextEditingValue _value(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

void main() {
  group('CustomInputField', () {
    Future<void> pumpField(WidgetTester tester, CustomInputField field) =>
        tester.pumpApp(Scaffold(body: field));

    testWidgets('the label is visible, not hidden in the placeholder', (
      tester,
    ) async {
      await pumpField(
        tester,
        const CustomInputField(label: 'Account number', hint: '0123456789'),
      );

      expect(find.text('Account number'), findsOneWidget);
      expect(find.text('0123456789'), findsOneWidget);
    });

    testWidgets('helper text explains the format before it is wrong', (
      tester,
    ) async {
      await pumpField(
        tester,
        const CustomInputField(label: 'Account number', helper: 'Ten digits'),
      );

      expect(find.text('Ten digits'), findsOneWidget);
    });

    testWidgets('an error replaces the helper rather than stacking', (
      tester,
    ) async {
      await pumpField(
        tester,
        const CustomInputField(
          label: 'Account number',
          helper: 'Ten digits',
          errorText: 'That is not ten digits',
        ),
      );

      expect(find.text('That is not ten digits'), findsOneWidget);
      expect(find.text('Ten digits'), findsNothing);
    });

    testWidgets('typing reaches the caller', (tester) async {
      String? seen;
      await pumpField(
        tester,
        CustomInputField(label: 'Amount', onChanged: (value) => seen = value),
      );

      await tester.enterText(find.byType(TextField), '5000');
      expect(seen, '5000');
    });

    testWidgets('a prefix renders beside the value', (tester) async {
      await pumpField(
        tester,
        const CustomInputField(label: 'Amount', prefix: Text('₦')),
      );

      expect(find.text('₦'), findsOneWidget);
    });

    testWidgets('the field is at least 52 tall', (tester) async {
      await pumpField(tester, const CustomInputField(label: 'Amount'));

      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(52),
      );
    });
  });

  group('AmountInputFormatter', () {
    const formatter = AmountInputFormatter();

    test('digits and one decimal point are allowed', () {
      expect(
        formatter.formatEditUpdate(_value(''), _value('5000')).text,
        '5000',
      );
      expect(
        formatter.formatEditUpdate(_value('5000'), _value('5000.2')).text,
        '5000.2',
      );
      expect(
        formatter.formatEditUpdate(_value('5000.2'), _value('5000.25')).text,
        '5000.25',
      );
    });

    test('a third decimal is refused, so no kobo is ever rounded away', () {
      expect(
        formatter.formatEditUpdate(_value('5000.25'), _value('5000.256')).text,
        '5000.25',
      );
    });

    test('letters and a second point are refused', () {
      expect(
        formatter.formatEditUpdate(_value('50'), _value('50a')).text,
        '50',
      );
      expect(
        formatter.formatEditUpdate(_value('5.0'), _value('5.0.')).text,
        '5.0',
      );
    });

    test(
      'a grouped value can never be edited again, so nothing feeds it one',
      () {
        expect(
          formatter
              .formatEditUpdate(_value('5,000.00'), _value('5,000.0'))
              .text,
          '5,000.00',
        );
      },
    );
  });
}
