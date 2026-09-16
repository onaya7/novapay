import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_scaffold.dart';

import '../../helpers/helpers.dart';

void main() {
  group('CustomScaffold', () {
    testWidgets('paints the canvas and pads the body', (tester) async {
      await tester.pumpApp(const CustomScaffold(body: Text('Wallet')));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppThemeColors.light.background);
      expect(scaffold.appBar, isNull);
      expect(find.text('Wallet'), findsOneWidget);
    });

    testWidgets('a title raises an app bar', (tester) async {
      await tester.pumpApp(
        const CustomScaffold(title: 'Send Money', body: SizedBox.shrink()),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Send Money'), findsOneWidget);
    });

    testWidgets('an explicit back handler replaces the implied one', (
      tester,
    ) async {
      var backs = 0;
      await tester.pumpApp(
        CustomScaffold(
          title: 'Amount',
          onBackPressed: () => backs++,
          body: const SizedBox.shrink(),
        ),
      );

      await tester.tap(find.byTooltip('Back'));
      expect(backs, 1);
    });

    testWidgets('back can be suppressed on a root screen', (tester) async {
      await tester.pumpApp(
        CustomScaffold(
          title: 'Wallet',
          showBackButton: false,
          onBackPressed: () {},
          body: const SizedBox.shrink(),
        ),
      );

      expect(
        tester.widget<AppBar>(find.byType(AppBar)).automaticallyImplyLeading,
        isFalse,
      );
      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets('a bottom bar pins below the body', (tester) async {
      await tester.pumpApp(
        const CustomScaffold(
          body: SizedBox.shrink(),
          bottomBar: Text('Send ₦5,000.00'),
        ),
      );

      expect(find.text('Send ₦5,000.00'), findsOneWidget);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
        isNotNull,
      );
    });

    testWidgets('a full-bleed screen opts out of the safe area', (
      tester,
    ) async {
      await tester.pumpApp(
        const CustomScaffold(
          safeArea: false,
          padding: EdgeInsets.zero,
          body: Text('Splash'),
        ),
      );

      expect(find.byType(SafeArea), findsNothing);
    });
  });
}
