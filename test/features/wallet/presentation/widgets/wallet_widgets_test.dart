import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/components/quick_action_tile.dart';
import 'package:novapay/core/components/section_header.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/components/status_chip.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/presentation/widgets/wallet_widgets.dart';

import '../../../../helpers/helpers.dart';

ActivityItem _item({
  int amountKobo = -500000,
  ActivityStatus status = ActivityStatus.settled,
  String title = 'To 0123456789',
}) => ActivityItem(
  id: 'a1',
  title: title,
  amountKobo: amountKobo,
  occurredAt: DateTime.now(),
  status: status,
);

void main() {
  group('BalanceCard', () {
    const committed = WalletSnapshot(
      confirmedKobo: 24800000,
      pendingKobo: 500000,
      activity: [],
    );
    const settled = WalletSnapshot(
      confirmedKobo: 24800000,
      pendingKobo: 0,
      activity: [],
    );

    testWidgets('leads with available, and shows the wallet total beneath', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const BalanceCard(snapshot: committed));

      expect(find.text('₦243,000.00'), findsOneWidget);
      expect(find.text('₦248,000.00'), findsOneWidget);
      expect(find.text('Wallet balance'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Available balance, two hundred and forty-three thousand naira',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('names committed money rather than hiding it', (tester) async {
      await tester.pumpApp(const BalanceCard(snapshot: committed));

      expect(find.text('sending'), findsOneWidget);
      expect(find.text('₦5,000.00'), findsOneWidget);
    });

    testWidgets('with nothing pending it shows one figure, not two', (
      tester,
    ) async {
      await tester.pumpApp(const BalanceCard(snapshot: settled));

      expect(find.text('sending'), findsNothing);
      expect(find.text('Wallet balance'), findsNothing);
      // Available equals the wallet balance here, so printing it twice would
      // be noise rather than reassurance.
      expect(find.text('₦248,000.00'), findsOneWidget);
    });

    testWidgets('a large balance scales down rather than overflowing', (
      tester,
    ) async {
      await tester.pumpApp(
        const BalanceCard(
          snapshot: WalletSnapshot(
            confirmedKobo: 9007199254740991,
            pendingKobo: 0,
            activity: [],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('₦90,071,992,547,409.91'), findsOneWidget);
    });

    testWidgets('the balance can be hidden from a shoulder', (tester) async {
      await tester.pumpApp(const BalanceCard(snapshot: committed));
      expect(find.text('₦243,000.00'), findsOneWidget);

      await tester.tap(find.byTooltip('Hide balance'));
      await tester.pump();

      expect(find.text('₦243,000.00'), findsNothing);
      expect(find.text('₦248,000.00'), findsNothing);
      expect(find.text('••••••'), findsNWidgets(2));
      expect(find.byTooltip('Show balance'), findsOneWidget);
    });

    testWidgets('hiding is reversible', (tester) async {
      await tester.pumpApp(const BalanceCard(snapshot: settled));

      await tester.tap(find.byTooltip('Hide balance'));
      await tester.pump();
      await tester.tap(find.byTooltip('Show balance'));
      await tester.pump();

      expect(find.text('₦248,000.00'), findsOneWidget);
    });
  });

  group('WalletHeader', () {
    testWidgets('greets without inventing a person', (tester) async {
      await tester.pumpApp(
        const WalletHeader(title: 'Wallet', greeting: 'Good afternoon'),
      );

      expect(find.text('Good afternoon'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.byType(AppAvatar), findsOneWidget);
    });
  });

  group('ActivityRow', () {
    testWidgets('a settled row carries no chip', (tester) async {
      await tester.pumpApp(ActivityRow(item: _item()));

      expect(find.text('To 0123456789'), findsOneWidget);
      expect(find.text('-₦5,000.00'), findsOneWidget);
      expect(find.byType(StatusChip), findsNothing);
    });

    testWidgets('a queued row says Pending in the word', (tester) async {
      await tester.pumpApp(
        ActivityRow(item: _item(status: ActivityStatus.pending)),
      );

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('a refused row says it did not go, and why', (tester) async {
      await tester.pumpApp(
        ActivityRow(
          item: _item(status: ActivityStatus.rejected)
              .copyWith(failureMessage: 'Not enough in your wallet'),
        ),
      );

      expect(find.text('Not sent'), findsOneWidget);
      expect(find.text('Not enough in your wallet'), findsOneWidget);
    });

    testWidgets('an unknown outcome never says Failed', (tester) async {
      await tester.pumpApp(
        ActivityRow(item: _item(status: ActivityStatus.unresolved)),
      );

      expect(find.text('Unresolved'), findsOneWidget);
      expect(find.textContaining('Failed'), findsNothing);
      // The customer is told to check, not invited to send it again.
      expect(
        find.textContaining("We couldn't confirm this transfer"),
        findsOneWidget,
      );
    });

    testWidgets('money arriving points the other way and is signed', (
      tester,
    ) async {
      await tester.pumpApp(
        ActivityRow(item: _item(amountKobo: 500000, title: 'From Ada')),
      );

      expect(find.text('+₦5,000.00'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('money leaving points up', (tester) async {
      await tester.pumpApp(ActivityRow(item: _item()));

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('a row is at least 66 tall so it stays tappable', (
      tester,
    ) async {
      await tester.pumpApp(ActivityRow(item: _item()));

      expect(
        tester.getSize(find.byType(ActivityRow)).height,
        greaterThanOrEqualTo(66),
      );
    });
  });

  group('WalletActions', () {
    testWidgets('Send is live and named', (tester) async {
      var sends = 0;
      await tester.pumpApp(WalletActions(onSend: () => sends++));

      expect(find.text('Send'), findsOneWidget);
      await tester.tap(find.text('Send'));
      expect(sends, 1);
    });

    testWidgets('what is not built yet stays visible and dead', (tester) async {
      await tester.pumpApp(WalletActions(onSend: () {}));

      expect(find.byType(QuickActionTile), findsNWidgets(4));
      final tiles = tester
          .widgetList<QuickActionTile>(find.byType(QuickActionTile))
          .toList();
      expect(tiles[0].onTap, isNotNull);
      expect(tiles[1].onTap, isNull);
      expect(tiles[2].onTap, isNull);
      expect(tiles[3].onTap, isNull);
      expect(find.text('Add money'), findsOneWidget);
    });

    testWidgets('Save wires up once it is given a callback', (tester) async {
      var saves = 0;
      await tester.pumpApp(WalletActions(onSend: () {}, onSave: () => saves++));

      await tester.tap(find.text('Save'));
      expect(saves, 1);
    });
  });

  group('WalletSkeleton', () {
    testWidgets('reserves the header, card, actions and three rows', (
      tester,
    ) async {
      // Scrolled, because that is how the page mounts it: taller than a small
      // viewport is correct for a skeleton that stands in for a full page.
      await tester.pumpApp(
        const SingleChildScrollView(child: WalletSkeleton()),
      );

      expect(find.byType(SkeletonBox), findsNWidgets(11));
    });
  });
}
