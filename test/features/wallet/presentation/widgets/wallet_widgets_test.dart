import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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
    testWidgets('leads with available, not confirmed', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const BalanceCard(
          snapshot: WalletSnapshot(
            confirmedKobo: 24800000,
            pendingKobo: 500000,
            activity: [],
          ),
        ),
      );

      expect(find.text('₦243,000.00'), findsOneWidget);
      expect(find.text('₦248,000.00'), findsNothing);
      expect(
        find.bySemanticsLabel(
          'Available balance, two hundred and forty-three thousand naira',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('names committed money rather than hiding it', (tester) async {
      await tester.pumpApp(
        const BalanceCard(
          snapshot: WalletSnapshot(
            confirmedKobo: 24800000,
            pendingKobo: 500000,
            activity: [],
          ),
        ),
      );

      expect(find.text('Sending'), findsOneWidget);
      expect(find.text('₦5,000.00'), findsOneWidget);
    });

    testWidgets('no committed money means no second line', (tester) async {
      await tester.pumpApp(
        const BalanceCard(
          snapshot: WalletSnapshot(
            confirmedKobo: 24800000,
            pendingKobo: 0,
            activity: [],
          ),
        ),
      );

      expect(find.text('Sending'), findsNothing);
      expect(find.text('₦248,000.00'), findsOneWidget);
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

    testWidgets('an exhausted row says what happened, not Failed', (
      tester,
    ) async {
      await tester.pumpApp(
        ActivityRow(item: _item(status: ActivityStatus.failed)),
      );

      expect(find.text('Not sent'), findsOneWidget);
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

  group('WalletSkeleton', () {
    testWidgets('reserves the card and three rows', (tester) async {
      await tester.pumpApp(const WalletSkeleton());

      expect(find.byType(SkeletonBox), findsNWidgets(5));
    });
  });
}
