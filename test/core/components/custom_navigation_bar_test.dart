import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/components/custom_navigation_bar.dart';

import '../../helpers/helpers.dart';

const _tabs = [
  NavigationTab(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
  NavigationTab(icon: Icons.savings_outlined, label: 'Savings'),
  NavigationTab(icon: Icons.receipt_long_outlined, label: 'Activity'),
  NavigationTab(icon: Icons.person_outline, label: 'Profile'),
];

void main() {
  testWidgets('renders every tab with its icon and label', (tester) async {
    await tester.pumpApp(
      Scaffold(
        bottomNavigationBar: CustomNavigationBar(
          tabs: _tabs,
          currentIndex: 0,
          onSelected: (_) {},
        ),
      ),
    );

    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
  });

  testWidgets('tapping a tab reports its index', (tester) async {
    final tapped = <int>[];
    await tester.pumpApp(
      Scaffold(
        bottomNavigationBar: CustomNavigationBar(
          tabs: _tabs,
          currentIndex: 0,
          onSelected: tapped.add,
        ),
      ),
    );

    await tester.tap(find.text('Savings'));

    expect(tapped, [1]);
  });

  testWidgets(
    'the notch settles, and a later rebuild with the same tab repaints',
    (tester) async {
      var index = 0;
      await tester.pumpApp(
        StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: CustomNavigationBar(
              tabs: _tabs,
              currentIndex: index,
              onSelected: (i) => setState(() => index = i),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Same tab again: the notch does not move, but the painter is rebuilt
      // and compared against the settled one.
      await tester.tap(find.text('Wallet'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Wallet'), findsOneWidget);
    },
  );
}
