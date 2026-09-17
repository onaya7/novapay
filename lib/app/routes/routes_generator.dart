import 'package:go_router/go_router.dart';
import 'package:novapay/app/routes/routes_name.dart';
import 'package:novapay/app/routes/routes_path.dart';
import 'package:novapay/app/view/app_shell.dart';
import 'package:novapay/features/funding/presentation/view/add_money_page.dart';
import 'package:novapay/features/profile/presentation/view/profile_page.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/presentation/view/contribute_page.dart';
import 'package:novapay/features/savings/presentation/view/create_goal_page.dart';
import 'package:novapay/features/savings/presentation/view/savings_page.dart';
import 'package:novapay/features/send_money/presentation/view/send_money_page.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/presentation/view/activity_page.dart';
import 'package:novapay/features/wallet/presentation/view/transaction_detail_page.dart';
import 'package:novapay/features/wallet/presentation/view/wallet_page.dart';

/// Every task screen, pushed as a top-level route over the whole shell,
/// matching what `Navigator.push` did before this. Exposed separately so a
/// test router can compose the same real destinations with its own root.
final List<RouteBase> taskRoutes = [
  GoRoute(
    path: RoutesPath.sendMoney,
    name: RoutesName.sendMoney,
    builder: (context, state) => const SendMoneyPage(),
  ),
  GoRoute(
    path: RoutesPath.addMoney,
    name: RoutesName.addMoney,
    builder: (context, state) => const AddMoneyPage(),
  ),
  GoRoute(
    path: RoutesPath.createGoal,
    name: RoutesName.createGoal,
    builder: (context, state) => const CreateGoalPage(),
  ),
  GoRoute(
    path: RoutesPath.contribute,
    name: RoutesName.contribute,
    builder: (context, state) =>
        ContributePage(goal: state.extra! as SavingsGoalItem),
  ),
  GoRoute(
    path: RoutesPath.transactionDetail,
    name: RoutesName.transactionDetail,
    builder: (context, state) =>
        TransactionDetailPage(item: state.extra! as ActivityItem),
  ),
];

/// The four tabs are branches, so each keeps its own back stack and scroll
/// position across a switch.
GoRouter buildRouter() => GoRouter(
  initialLocation: RoutesPath.wallet,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutesPath.wallet,
              name: RoutesName.wallet,
              builder: (context, state) => const WalletPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutesPath.savings,
              name: RoutesName.savings,
              builder: (context, state) => const SavingsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutesPath.activity,
              name: RoutesName.activity,
              builder: (context, state) => const ActivityPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutesPath.profile,
              name: RoutesName.profile,
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
    ...taskRoutes,
  ],
);
