import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_navigation_bar.dart';

/// The four destinations. Send Money, Create Goal, Contribute and Add Money
/// are tasks, so they are pushed over the shell rather than tabbed.
const List<NavigationTab> kNavigationTabs = [
  NavigationTab(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
  NavigationTab(icon: Icons.savings_outlined, label: 'Savings'),
  NavigationTab(icon: Icons.receipt_long_outlined, label: 'Activity'),
  NavigationTab(icon: Icons.person_outline, label: 'Profile'),
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
      // So scrolling content is visible through the translucent bar rather
      // than stopping dead at its top edge.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: CustomNavigationBar(
        tabs: kNavigationTabs,
        currentIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
