import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';

ActivityItem _item({
  int amountKobo = -500000,
  ActivityStatus status = ActivityStatus.settled,
}) => ActivityItem(
  id: 'a1',
  title: 'To 0123456789',
  amountKobo: amountKobo,
  occurredAt: DateTime(2026, 9, 16),
  status: status,
);

void main() {
  group('ActivityItem', () {
    test('reads its amount as money, never as a double', () {
      expect(_item().amount, const Money.fromKobo(-500000));
      expect(_item().amount.format(), '-₦5,000.00');
    });

    test('money leaving is a debit', () {
      expect(_item().isDebit, isTrue);
      expect(_item(amountKobo: 500000).isDebit, isFalse);
    });

    test('only the exceptions are annotated', () {
      expect(_item().needsChip, isFalse);
      expect(_item(status: ActivityStatus.pending).needsChip, isTrue);
      expect(_item(status: ActivityStatus.unresolved).needsChip, isTrue);
    });
  });

  group('WalletSnapshot', () {
    test('available is confirmed minus what is already committed', () {
      const snapshot = WalletSnapshot(
        confirmedKobo: 24800000,
        pendingKobo: 500000,
        activity: [],
      );

      expect(snapshot.confirmed.format(), '₦248,000.00');
      expect(snapshot.pending.format(), '₦5,000.00');
      expect(snapshot.available.format(), '₦243,000.00');
    });

    test('available can go negative rather than silently clamping', () {
      const snapshot = WalletSnapshot(
        confirmedKobo: 100,
        pendingKobo: 500,
        activity: [],
      );

      expect(snapshot.available, const Money.fromKobo(-400));
    });

    test('nothing committed means nothing to announce', () {
      const snapshot = WalletSnapshot(
        confirmedKobo: 100,
        pendingKobo: 0,
        activity: [],
      );

      expect(snapshot.hasPending, isFalse);
      expect(snapshot.hasActivity, isFalse);
    });

    test('an activity list is reported as present', () {
      final snapshot = WalletSnapshot(
        confirmedKobo: 100,
        pendingKobo: 1,
        activity: [_item()],
      );

      expect(snapshot.hasPending, isTrue);
      expect(snapshot.hasActivity, isTrue);
    });
  });
}
