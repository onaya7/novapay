import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/routes/routes_generator.dart';
import 'package:novapay/app/routes/routes_name.dart';
import 'package:novapay/app/routes/routes_path.dart';
import 'package:novapay/config/theme/app_theme.dart';
import 'package:novapay/features/profile/presentation/view/profile_page.dart';
import 'package:novapay/features/savings/presentation/view/savings_page.dart';
import 'package:novapay/features/wallet/presentation/view/activity_page.dart';
import 'package:novapay/features/wallet/presentation/view/wallet_page.dart';
import 'package:novapay/l10n/l10n.dart';

const String _harnessRootPath = '/__pump_app__';
const String _harnessLeafPath = 'widget';
const String _harnessLeafFullPath = '$_harnessRootPath/$_harnessLeafPath';

/// The four tabs, as flat routes rather than a `StatefulShellRoute` — a test
/// exercising `context.goNamed` into a tab needs the real destination
/// reachable, but not the shell chrome around it.
final List<RouteBase> _tabRoutes = [
  GoRoute(
    path: RoutesPath.wallet,
    name: RoutesName.wallet,
    builder: (_, _) => const WalletPage(),
  ),
  GoRoute(
    path: RoutesPath.savings,
    name: RoutesName.savings,
    builder: (_, _) => const SavingsPage(),
  ),
  GoRoute(
    path: RoutesPath.activity,
    name: RoutesName.activity,
    builder: (_, _) => const ActivityPage(),
  ),
  GoRoute(
    path: RoutesPath.profile,
    name: RoutesName.profile,
    builder: (_, _) => const ProfilePage(),
  ),
];

extension PumpApp on WidgetTester {
  /// Renders [widget] behind a real `GoRouter`, carrying the same named
  /// routes the app ships, so a `context.pushNamed`/`goNamed`/`pop` inside
  /// [widget] resolves exactly as it does in the app rather than throwing
  /// for want of a `Router` ancestor or an unknown route name.
  Future<void> pumpApp(Widget widget, {ThemeData? theme}) {
    final router = GoRouter(
      initialLocation: _harnessLeafFullPath,
      routes: [
        // A nested child route, not a sibling: this gives [widget] a real
        // parent to pop back to, the same way `Navigator.pop()` used to
        // leave something behind rather than popping to nothing.
        GoRoute(
          path: _harnessRootPath,
          builder: (_, _) => const SizedBox.shrink(),
          routes: [GoRoute(path: _harnessLeafPath, builder: (_, _) => widget)],
        ),
        ..._tabRoutes,
        ...taskRoutes,
      ],
    );
    return pumpWidget(
      MaterialApp.router(
        theme: theme ?? AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}
