import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/presentation/view/transaction_detail_page.dart';

import '../../../../helpers/helpers.dart';

ActivityItem _item({
  int amountKobo = -500000,
  ActivityStatus status = ActivityStatus.settled,
  String? failureMessage,
}) => ActivityItem(
  id: 'a1',
  title: 'To Guaranty Trust Bank, •••••• 6789',
  amountKobo: amountKobo,
  occurredAt: DateTime(2026, 9, 16, 9, 5),
  status: status,
  failureMessage: failureMessage,
);

void main() {
  testWidgets('shows the description, date, time and reference', (
    tester,
  ) async {
    await tester.pumpApp(TransactionDetailPage(item: _item()));

    expect(find.text('To Guaranty Trust Bank, •••••• 6789'), findsOneWidget);
    expect(find.text('a1'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget);
  });

  testWidgets('money leaving is signed negative', (tester) async {
    await tester.pumpApp(TransactionDetailPage(item: _item()));

    expect(find.text('-₦5,000.00'), findsOneWidget);
  });

  testWidgets('money arriving is signed positive', (tester) async {
    await tester.pumpApp(
      TransactionDetailPage(item: _item(amountKobo: 500000)),
    );

    expect(find.text('+₦5,000.00'), findsOneWidget);
  });

  testWidgets('a settled row gets a chip here, unlike the compact row', (
    tester,
  ) async {
    await tester.pumpApp(TransactionDetailPage(item: _item()));

    expect(find.text('Settled'), findsOneWidget);
  });

  testWidgets('a pending row says so', (tester) async {
    await tester.pumpApp(
      TransactionDetailPage(item: _item(status: ActivityStatus.pending)),
    );

    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('a rejected row names the reason', (tester) async {
    await tester.pumpApp(
      TransactionDetailPage(
        item: _item(
          status: ActivityStatus.rejected,
          failureMessage: 'Not enough in your wallet',
        ),
      ),
    );

    expect(find.text('Not sent'), findsOneWidget);
    expect(find.text('Not enough in your wallet'), findsOneWidget);
  });

  testWidgets('an unresolved row asks the customer to check, not retry', (
    tester,
  ) async {
    await tester.pumpApp(
      TransactionDetailPage(item: _item(status: ActivityStatus.unresolved)),
    );

    expect(find.text('Unresolved'), findsOneWidget);
    expect(
      find.textContaining("We couldn't confirm this transfer"),
      findsOneWidget,
    );
  });
}
