import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/l10n/l10n.dart';

/// Built by `StatefulShellRoute.indexedStack` in `routes_generator.dart`; the
/// shell itself owns which branch is current, so nothing duplicates that as
/// separate state.
class AppShell extends StatelessWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppThemeColors.of(context).background,
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: l10n.walletTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.savings_outlined),
            label: l10n.savingsLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            label: l10n.activityLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: l10n.profileLabel,
          ),
        ],
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
