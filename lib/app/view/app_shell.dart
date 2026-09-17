import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';

const List<BottomNavigationBarItem> kNavigationItems = [
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

/// Built by `StatefulShellRoute.indexedStack` in `routes_generator.dart`; the
/// shell itself owns which branch is current, so nothing duplicates that as
/// separate state.
class AppShell extends StatelessWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.of(context).background,
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        items: kNavigationItems,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppThemeColors.of(context).primary,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
