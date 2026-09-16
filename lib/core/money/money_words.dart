import 'package:novapay/core/money/money.dart';

const List<String> _units = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
];

const List<String> _tens = [
  '',
  '',
  'twenty',
  'thirty',
  'forty',
  'fifty',
  'sixty',
  'seventy',
  'eighty',
  'ninety',
];

const List<(int, String)> _scales = [
  (1000000000000, 'trillion'),
  (1000000000, 'billion'),
  (1000000, 'million'),
  (1000, 'thousand'),
];

/// What a screen reader should say, because raw text reads as digit soup.
String spokenMoney(Money amount) {
  final magnitude = amount.kobo.abs();
  final naira = magnitude ~/ 100;
  final kobo = magnitude % 100;

  final buffer = StringBuffer();
  if (amount.isNegative) buffer.write('minus ');
  buffer.write('${numberToWords(naira)} naira');
  if (kobo > 0) buffer.write(', ${numberToWords(kobo)} kobo');
  return buffer.toString();
}

String numberToWords(int value) {
  if (value < 20) return _units[value];
  if (value < 100) {
    final tens = _tens[value ~/ 10];
    final remainder = value % 10;
    return remainder == 0 ? tens : '$tens-${_units[remainder]}';
  }
  if (value < 1000) {
    final hundreds = '${_units[value ~/ 100]} hundred';
    final remainder = value % 100;
    return remainder == 0
        ? hundreds
        : '$hundreds and ${numberToWords(remainder)}';
  }
  final (size, name) = _scales.firstWhere((scale) => value >= scale.$1);
  final head = '${numberToWords(value ~/ size)} $name';
  final remainder = value % size;
  if (remainder == 0) return head;
  // English joins a sub-hundred tail with "and": one thousand and five.
  final joiner = remainder < 100 ? ' and ' : ' ';
  return '$head$joiner${numberToWords(remainder)}';
}
