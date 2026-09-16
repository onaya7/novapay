import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/state_widgets.dart';

import '../../helpers/helpers.dart';

void main() {
  group('LoadingIndicator', () {
    testWidgets('spins at the size it is given', (tester) async {
      // A const instance is canonicalized, so the constructor never runs.
      // ignore: prefer_const_constructors
      await tester.pumpApp(LoadingIndicator(size: 32));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.getSize(find.byType(CircularProgressIndicator)),
        const Size(32, 32),
      );
    });
  });

  group('SkeletonBox', () {
    testWidgets('reserves the shape the content will take', (tester) async {
      await tester.pumpApp(
        // A const instance is canonicalized, so the constructor never runs.
        // ignore: prefer_const_constructors
        Center(child: SkeletonBox(height: 24, width: 120)),
      );

      final box = tester.widget<Container>(find.byType(Container));
      expect(tester.getSize(find.byType(Container)), const Size(120, 24));
      expect(
        (box.decoration! as BoxDecoration).color,
        AppThemeColors.light.fill,
      );
    });
  });

  group('AppErrorState', () {
    testWidgets('offers a way out of the error', (tester) async {
      var retries = 0;
      await tester.pumpApp(
        AppErrorState(
          message: "We couldn't reach NovaPay. Check your connection.",
          onRetry: () => retries++,
        ),
      );

      await tester.tap(find.byType(CustomButton));
      expect(retries, 1);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('renames the way out when the fix is not a retry', (
      tester,
    ) async {
      await tester.pumpApp(
        AppErrorState(
          message: 'Not enough in your wallet.',
          onRetry: () {},
          retryLabel: 'Fund Wallet',
        ),
      );

      expect(find.text('Fund Wallet'), findsOneWidget);
    });

    testWidgets('shows the message alone when nothing can be retried', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppErrorState(message: 'That goal no longer exists.'),
      );

      expect(find.text('That goal no longer exists.'), findsOneWidget);
      expect(find.byType(CustomButton), findsNothing);
    });
  });

  group('AppEmptyState', () {
    testWidgets('an empty list still names its next step', (tester) async {
      await tester.pumpApp(
        AppEmptyState(
          message: 'No transactions yet.',
          icon: Icons.receipt_long,
          action: CustomButton(
            label: 'Send money',
            onPressed: () {},
            expand: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.text('Send money'), findsOneWidget);
    });

    testWidgets('falls back to the default icon and no action', (tester) async {
      await tester.pumpApp(const AppEmptyState(message: 'Nothing here yet.'));

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.byType(CustomButton), findsNothing);
    });
  });

  group('PullToRefreshBody', () {
    testWidgets('fills the viewport so a short list still pulls', (
      tester,
    ) async {
      await tester.pumpApp(const PullToRefreshBody(child: Text('One row')));

      final height = tester.getSize(find.byType(ConstrainedBox).first).height;
      expect(height, greaterThan(400));
      expect(find.text('One row'), findsOneWidget);
    });

    testWidgets('can centre its child instead of topping it', (tester) async {
      await tester.pumpApp(
        const PullToRefreshBody(
          alignment: Alignment.center,
          child: Text('Nothing yet'),
        ),
      );

      expect(
        tester.widget<Align>(find.byType(Align).last).alignment,
        Alignment.center,
      );
    });
  });
}
