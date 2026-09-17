import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/extensions/date_time_extension.dart';
import 'package:novapay/core/extensions/int_extension.dart';
import 'package:novapay/core/extensions/string_extension.dart';
import 'package:novapay/core/money/money.dart';

void main() {
  group('StringX', () {
    test('recognizes a ten-digit account number', () {
      expect('0123456789'.isAccountNumber, isTrue);
      expect('012345678'.isAccountNumber, isFalse);
      expect('01234567890'.isAccountNumber, isFalse);
      expect('01234S6789'.isAccountNumber, isFalse);
      expect(''.isAccountNumber, isFalse);
    });

    test('masks all but the last four digits', () {
      expect('0123456789'.maskedAccountNumber, '•••••• 6789');
      expect('6789'.maskedAccountNumber, '6789');
      expect('89'.maskedAccountNumber, '89');
    });

    test('takes up to two initials', () {
      expect('Adaeze Okonkwo'.initials, 'AO');
      expect('  chidi   obi   eze '.initials, 'CO');
      expect('Ngozi'.initials, 'N');
      expect('   '.initials, '?');
      expect(''.initials, '?');
    });

    test('capitalizes without touching the rest', () {
      expect('rent'.capitalized, 'Rent');
      expect('Rent'.capitalized, 'Rent');
      expect(''.capitalized, '');
    });

    test('parses an amount the customer typed', () {
      expect('0.29'.asMoney, const Money.fromKobo(29));
      expect('₦1,000.00'.asMoney, const Money.fromKobo(100000));
      expect('not money'.asMoney, isNull);
    });

    test('falls back when blank', () {
      expect('   '.orIfBlank('Unnamed'), 'Unnamed');
      expect('Rent'.orIfBlank('Unnamed'), 'Rent');
    });
  });

  group('IntX', () {
    test('reads an integer as kobo or as whole naira', () {
      expect(500000.kobo, const Money.fromKobo(500000));
      expect(5000.naira, const Money.fromKobo(500000));
      expect(5000.naira.format(), '₦5,000.00');
    });

    test('ordinals read correctly, including the teens', () {
      expect(1.ordinal, '1st');
      expect(2.ordinal, '2nd');
      expect(3.ordinal, '3rd');
      expect(4.ordinal, '4th');
      expect(11.ordinal, '11th');
      expect(12.ordinal, '12th');
      expect(13.ordinal, '13th');
      expect(21.ordinal, '21st');
      expect(112.ordinal, '112th');
      expect(0.ordinal, '0th');
    });
  });

  group('DateTimeX', () {
    test('knows today and yesterday', () {
      final now = DateTime.now();
      expect(now.isToday, isTrue);
      expect(now.isYesterday, isFalse);
      expect(now.subtract(const Duration(days: 1)).isYesterday, isTrue);
      expect(now.subtract(const Duration(days: 2)).isToday, isFalse);
    });

    test('compares calendar days, not instants', () {
      expect(
        DateTime(2026, 9, 16, 1).isSameDayAs(DateTime(2026, 9, 16, 23)),
        isTrue,
      );
      expect(DateTime(2026, 9, 16).isSameDayAs(DateTime(2026, 9, 17)), isFalse);
    });

    test('labels a row the way a statement does', () {
      final now = DateTime.now();
      expect(now.dayLabel, 'Today');
      expect(now.subtract(const Duration(days: 1)).dayLabel, 'Yesterday');
      expect(DateTime(now.year, 1, 14).dayLabel, '14 Jan');
      expect(DateTime(2020, 1, 14).dayLabel, '14 Jan 2020');
    });

    test('shows a clock time', () {
      expect(DateTime(2026, 9, 16, 9, 5).timeLabel, '09:05');
    });

    test('counts whole days from today', () {
      final now = DateTime.now();
      expect(now.daysFromNow, 0);
      expect(now.add(const Duration(days: 3)).daysFromNow, 3);
      expect(now.subtract(const Duration(days: 2)).daysFromNow, -2);
    });

    test('greets by the hour, not by whatever hour the suite runs at', () {
      expect(DateTime(2026, 9, 16, 6).greeting, 'Good morning');
      expect(DateTime(2026, 9, 16, 11, 59).greeting, 'Good morning');
      expect(DateTime(2026, 9, 16, 12).greeting, 'Good afternoon');
      expect(DateTime(2026, 9, 16, 16, 59).greeting, 'Good afternoon');
      expect(DateTime(2026, 9, 16, 17).greeting, 'Good evening');
      expect(DateTime(2026, 9, 16, 23).greeting, 'Good evening');
    });
  });
}
