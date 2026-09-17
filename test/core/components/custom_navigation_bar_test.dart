import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/helpers.dart';

const _items = [
  BottomNavigationBarItem(
    icon: Icon(Icons.account_balance_wallet_outlined),
    label: 'Wallet',
  ),
  BottomNavigationBarItem(icon: Icon(Icons.savings_outlined), label: 'Savings'),
  BottomNavigationBarItem(
    icon: Icon(Icons.receipt_long_outlined),
    label: 'Activity',
  ),
  BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
];

void main() {
  testWidgets('renders every tab with its icon and label', (tester) async {
    await tester.pumpApp(
      Scaffold(
        bottomNavigationBar: BottomNavigationBar(items: _items, onTap: (_) {}),
      ),
    );

    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
  });

  testWidgets('tapping a tab reports its index', (tester) async {
    var tappedIndex = -1;
    await tester.pumpApp(
      Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          items: _items,
          onTap: (index) => tappedIndex = index,
        ),
      ),
    );

    await tester.tap(find.text('Savings'));

    expect(tappedIndex, 1);
  });
}
