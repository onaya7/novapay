import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/money/money_words.dart';

void main() {
  group('numberToWords', () {
    test('reads the teens as single words', () {
      expect(numberToWords(0), 'zero');
      expect(numberToWords(7), 'seven');
      expect(numberToWords(19), 'nineteen');
    });

    test('hyphenates a tens value only when it has a unit', () {
      expect(numberToWords(20), 'twenty');
      expect(numberToWords(21), 'twenty-one');
      expect(numberToWords(99), 'ninety-nine');
    });

    test('joins a hundreds tail with and', () {
      expect(numberToWords(100), 'one hundred');
      expect(numberToWords(105), 'one hundred and five');
      expect(numberToWords(942), 'nine hundred and forty-two');
    });

    test('uses and only when the tail is below a hundred', () {
      expect(numberToWords(1000), 'one thousand');
      expect(numberToWords(1005), 'one thousand and five');
      expect(numberToWords(1500), 'one thousand five hundred');
    });

    test('climbs every scale', () {
      expect(
        numberToWords(2480000),
        'two million four hundred and eighty thousand',
      );
      expect(numberToWords(3000000000), 'three billion');
      expect(numberToWords(4000000000000), 'four trillion');
    });

    test('reads the largest exact amount', () {
      expect(
        numberToWords(Money.maxKobo ~/ 100),
        startsWith('ninety trillion'),
      );
    });
  });

  group('spokenMoney', () {
    test('says naira alone on a whole amount', () {
      expect(
        spokenMoney(Money.parse('2480000')),
        'two million four hundred and eighty thousand naira',
      );
    });

    test('adds the kobo half only when there is one', () {
      expect(spokenMoney(Money.parse('12.50')), 'twelve naira, fifty kobo');
      expect(spokenMoney(Money.parse('12.00')), 'twelve naira');
    });

    test('says zero rather than nothing', () {
      expect(spokenMoney(Money.zero), 'zero naira');
    });

    test('leads with minus on money leaving', () {
      expect(
        spokenMoney(Money.parse('-5000.29')),
        'minus five thousand naira, twenty-nine kobo',
      );
    });
  });
}
