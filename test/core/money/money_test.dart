import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/money/money.dart';

void main() {
  group('Money.parse', () {
    test('does not lose a kobo where a double would', () {
      // (double.parse('0.29') * 100).toInt() is 28, not 29.
      expect(Money.parse('0.29').kobo, 29);
      expect(Money.parse('1.15').kobo, 115);
      expect(Money.parse('8.87').kobo, 887);
      expect(Money.parse('19.99').kobo, 1999);
    });

    test('accepts the shapes a customer actually types', () {
      expect(Money.parse('.5').kobo, 50);
      expect(Money.parse('1.').kobo, 100);
      expect(Money.parse('1').kobo, 100);
      expect(Money.parse('0').kobo, 0);
      expect(Money.parse('  12.34  ').kobo, 1234);
    });

    test('accepts a pasted, formatted amount', () {
      expect(Money.parse('₦1,000.00').kobo, 100000);
      expect(Money.parse('₦ 2,480,000.00').kobo, 248000000);
      expect(Money.parse('1 000.00').kobo, 100000);
    });

    test('truncates a long fraction rather than rounding up', () {
      // Rounding up would invent money the customer did not have.
      expect(Money.parse('1.005').kobo, 100);
      expect(Money.parse('1.999').kobo, 199);
    });

    test('handles negatives', () {
      expect(Money.parse('-164.00').kobo, -16400);
      expect(Money.parse('-₦164').kobo, -16400);
    });

    test('rejects rubbish', () {
      const invalid = <String>[
        '',
        '   ',
        'abc',
        '1.2.3',
        '1,2.3.4',
        '12a.00',
        '1.0a',
        '-',
        '₦',
      ];
      for (final input in invalid) {
        expect(Money.tryParse(input), isNull, reason: 'should reject "$input"');
      }
      expect(() => Money.parse('abc'), throwsFormatException);
    });

    test('rejects a paste that exceeds exact integer range', () {
      expect(Money.tryParse('99999999999999999999'), isNull);
      expect(Money.tryParse('90071992547409.92'), isNull);
      expect(const Money.fromKobo(Money.maxKobo).kobo, Money.maxKobo);
    });
  });

  group('Money.format', () {
    test('matches the rendering the README specifies', () {
      expect(const Money.fromKobo(248000000).format(), '₦2,480,000.00');
      expect(const Money.fromKobo(1050).format(), '₦10.50');
      expect(const Money.fromKobo(29).format(), '₦0.29');
      expect(const Money.fromKobo(-16400).format(), '-₦164.00');
      expect(Money.zero.format(), '₦0.00');
      expect(const Money.fromKobo(99).format(), '₦0.99');
    });

    test('empty state is a zero amount, never a blank or a dash', () {
      expect(Money.zero.format(), '₦0.00');
      expect(Money.zero.format().isNotEmpty, isTrue);
    });

    test('can omit the symbol without changing the number', () {
      expect(const Money.fromKobo(1050).format(withSymbol: false), '10.50');
    });

    test('groups correctly at the top of the exact range', () {
      // Proves the grouping path holds for a very large integer, since the
      // formatter is handed only the naira half.
      expect(
        const Money.fromKobo(Money.maxKobo).format(),
        '₦90,071,992,547,409.91',
      );
    });
  });

  group('toEditableString', () {
    test('has no grouping, unlike format', () {
      expect(const Money.fromKobo(500000).toEditableString(), '5000.00');
    });

    test('round-trips through Money.parse', () {
      expect(
        Money.parse(const Money.fromKobo(29).toEditableString()),
        const Money.fromKobo(29),
      );
    });

    test('carries the sign', () {
      expect(const Money.fromKobo(-16400).toEditableString(), '-164.00');
    });
  });

  group('round trip', () {
    test('parse(format(k)) == k across boundaries', () {
      const values = <int>[
        0,
        1,
        29,
        99,
        100,
        101,
        999,
        1000,
        1050,
        100000,
        248000000,
        -1,
        -99,
        -16400,
        Money.maxKobo,
      ];
      for (final kobo in values) {
        final money = Money.fromKobo(kobo);
        expect(
          Money.parse(money.format()).kobo,
          kobo,
          reason: 'round trip failed for $kobo (${money.format()})',
        );
      }
    });
  });

  group('arithmetic', () {
    test('sums are exact, not approximate', () {
      final amounts = <Money>[
        Money.parse('0.10'),
        Money.parse('0.20'),
        Money.parse('0.30'),
        Money.parse('19.99'),
        Money.parse('0.29'),
      ];
      // Exact equality. closeTo has no place in a money test.
      expect(sumMoney(amounts).kobo, 2088);
      expect(sumMoney(amounts).format(), '₦20.88');
    });

    test('sum of nothing is zero', () {
      expect(sumMoney(const <Money>[]), Money.zero);
    });

    test('operators behave', () {
      final five = Money.parse('5.00');
      final three = Money.parse('3.00');
      expect((five + three).kobo, 800);
      expect((five - three).kobo, 200);
      expect((three - five).kobo, -200);
      expect((five * 3).kobo, 1500);
      expect((-five).kobo, -500);
      expect(five.abs().kobo, 500);
      expect((three - five).abs().kobo, 200);
      expect(five > three, isTrue);
      expect(three < five, isTrue);
      expect(five >= Money.parse('5.00'), isTrue);
      expect(five <= Money.parse('5.00'), isTrue);
      expect(Money.zero.isZero, isTrue);
      expect((three - five).isNegative, isTrue);
    });

    test('equality is by value', () {
      expect(Money.parse('10.50'), const Money.fromKobo(1050));
      expect(
        Money.parse('10.50').hashCode,
        const Money.fromKobo(1050).hashCode,
      );
      expect(Money.parse('10.50') == const Money.fromKobo(1051), isFalse);
    });

    test('sorts by value', () {
      final amounts = <Money>[
        const Money.fromKobo(300),
        const Money.fromKobo(-100),
        Money.zero,
      ]..sort();
      expect(amounts.map((m) => m.kobo).toList(), <int>[-100, 0, 300]);
    });
  });

  group('toString', () {
    test('describes itself as a formatted amount', () {
      expect(const Money.fromKobo(1050).toString(), 'Money(\u20a610.50)');
      expect(Money.zero.toString(), 'Money(\u20a60.00)');
      expect(const Money.fromKobo(-16400).toString(), 'Money(-\u20a6164.00)');
    });
  });

  group('koboFromJson', () {
    test('accepts an integer', () {
      expect(koboFromJson(1000), 1000);
      expect(koboFromJson(0), 0);
      expect(koboFromJson(-5), -5);
    });

    test('refuses a double rather than truncating it', () {
      // The tempting fix is .toInt(), which silently loses money.
      expect(() => koboFromJson(1000.0), throwsFormatException);
      expect(() => koboFromJson(10.5), throwsFormatException);
      expect(() => koboFromJson('1000'), throwsFormatException);
      expect(() => koboFromJson(null), throwsFormatException);
    });
  });

  group('progress', () {
    test('is computed in integer basis points', () {
      expect(
        progressBasisPoints(
          saved: const Money.fromKobo(3333),
          target: const Money.fromKobo(10000),
        ),
        3333,
      );
      expect(
        progressPercent(
          saved: const Money.fromKobo(3333),
          target: const Money.fromKobo(10000),
        ),
        33,
      );
    });

    test('a zero or negative target cannot divide by zero', () {
      expect(
        progressBasisPoints(
          saved: const Money.fromKobo(100),
          target: Money.zero,
        ),
        0,
      );
      expect(
        progressBasisPoints(
          saved: const Money.fromKobo(100),
          target: const Money.fromKobo(-5),
        ),
        0,
      );
    });

    test('clamps to the ends', () {
      expect(
        progressBasisPoints(
          saved: const Money.fromKobo(20000),
          target: const Money.fromKobo(10000),
        ),
        10000,
      );
      expect(
        progressBasisPoints(
          saved: const Money.fromKobo(-500),
          target: const Money.fromKobo(10000),
        ),
        0,
      );
      expect(
        progressPercent(
          saved: const Money.fromKobo(10000),
          target: const Money.fromKobo(10000),
        ),
        100,
      );
    });

    test('does not overflow near the top of the exact range', () {
      // saved * 10000 is 4.5e19 here, past the 9.22e18 int64 ceiling, so an
      // unguarded multiply would wrap. A quarter of 8e15 has an exact answer.
      expect(
        progressBasisPoints(
          saved: const Money.fromKobo(2000000000000000),
          target: const Money.fromKobo(8000000000000000),
        ),
        2500,
      );
      // maxKobo ~/ 2 floors to just under half, so the true value is
      // 4999.999999999999 and the floor is 4999, not 5000.
      expect(
        progressBasisPoints(
          saved: const Money.fromKobo(Money.maxKobo ~/ 2),
          target: const Money.fromKobo(Money.maxKobo),
        ),
        4999,
      );
    });

    test('truncates rather than flattering the saver', () {
      // 99.99% must not read as 100%.
      expect(
        progressPercent(
          saved: const Money.fromKobo(9999),
          target: const Money.fromKobo(10000),
        ),
        99,
      );
    });
  });
}
