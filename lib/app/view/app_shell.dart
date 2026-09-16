import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/presentation/cubit/nav_cubit.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_navigation_bar.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/profile/presentation/view/profile_page.dart';
import 'package:novapay/features/savings/presentation/view/savings_page.dart';
import 'package:novapay/features/wallet/presentation/view/activity_page.dart';
import 'package:novapay/features/wallet/presentation/view/wallet_page.dart';

/// The four destinations. Send Money, Create Goal, Contribute and Add Money
/// are tasks, so they are pushed over the shell rather than tabbed.
const List<NavigationTab> kNavigationTabs = [
  NavigationTab(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
  NavigationTab(icon: Icons.savings_outlined, label: 'Savings'),
  NavigationTab(icon: Icons.receipt_long_outlined, label: 'Activity'),
  NavigationTab(icon: Icons.person_outline, label: 'Profile'),
];

class AppShell extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NavCubit>(
      create: (_) => sl<NavCubit>(),
      child: const AppShellView(),
    );
  }
}

class AppShellView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavCubit, int>(
      builder: (context, index) => Scaffold(
        backgroundColor: AppThemeColors.of(context).background,
        // Indexed rather than rebuilt, so each tab keeps its scroll position
        // and its cubit across a switch.
        body: IndexedStack(
          index: index,
          children: const [
            WalletPage(),
            SavingsPage(),
            ActivityPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: CustomNavigationBar(
          tabs: kNavigationTabs,
          currentIndex: index,
          onSelected: context.read<NavCubit>().select,
        ),
      ),
    );
  }
}
