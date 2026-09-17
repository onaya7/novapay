import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/features/send_money/domain/entities/bank.dart';
import 'package:novapay/features/send_money/presentation/widgets/bank_picker_sheet.dart';

import '../../../../helpers/helpers.dart';

const _gtb = Bank(code: '058', name: 'Guaranty Trust Bank');
const _access = Bank(code: '044', name: 'Access Bank');

/// `showModalBottomSheet` brings its own `Material` in the real app; this
/// stands in for that so the sheet's `TextField` has the ancestor it needs.
Widget _sheet(List<Bank> banks) =>
    Material(child: BankPickerSheet(banks: banks));

void main() {
  testWidgets('lists every bank it is given', (tester) async {
    await tester.pumpApp(_sheet(const [_gtb, _access]));

    expect(find.text('Guaranty Trust Bank'), findsOneWidget);
    expect(find.text('Access Bank'), findsOneWidget);
  });

  testWidgets('clearing the search shows the full list again', (tester) async {
    await tester.pumpApp(_sheet(const [_gtb, _access]));

    await tester.enterText(find.byType(TextField), 'guaranty');
    await tester.pumpAndSettle();
    expect(find.text('Access Bank'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.text('Guaranty Trust Bank'), findsOneWidget);
    expect(find.text('Access Bank'), findsOneWidget);
  });

  testWidgets('a search matching nothing says so, not a blank list', (
    tester,
  ) async {
    await tester.pumpApp(_sheet(const [_gtb, _access]));

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No banks match that search'), findsOneWidget);
  });
}
