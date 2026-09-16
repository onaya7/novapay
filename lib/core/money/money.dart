import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

/// An exact amount of Naira, held as a whole number of kobo.
@immutable
class Money implements Comparable<Money> {
  const Money.fromKobo(this.kobo);

  /// Throws [FormatException] when [input] is not a valid amount.
  factory Money.parse(String input) {
    final parsed = tryParse(input);
    if (parsed == null) {
      throw FormatException('not a valid amount', input);
    }
    return parsed;
  }

  /// The amount in kobo. 100 kobo is one naira.
  final int kobo;

  static const Money zero = Money.fromKobo(0);

  /// Largest exact amount; on web an int is a 53-bit double.
  static const int maxKobo = 9007199254740991;

  static final NumberFormat _grouping = NumberFormat.decimalPattern();

  /// Null when invalid. Never builds a double: '0.29' must not become 28.
  static Money? tryParse(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;

    var negative = false;
    if (text.startsWith('-')) {
      negative = true;
      text = text.substring(1);
    }

    text = text
        .replaceAll('₦', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    if (text.isEmpty) return null;

    final parts = text.split('.');
    if (parts.length > 2) return null;

    final whole = parts.first;
    final fraction = parts.length == 2 ? parts[1] : '';
    if (whole.isEmpty && fraction.isEmpty) return null;
    if (!_digitsOnly(whole) || !_digitsOnly(fraction)) return null;

    // Truncated rather than rounded, so no amount is ever rounded up.
    final koboDigits = fraction.padRight(2, '0').substring(0, 2);
    final combined = (whole.isEmpty ? '0' : whole) + koboDigits;

    final value = int.tryParse(combined);
    if (value == null || value > maxKobo) return null;
    return Money.fromKobo(negative ? -value : value);
  }

  static bool _digitsOnly(String text) {
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      if (unit < 0x30 || unit > 0x39) return false;
    }
    return true;
  }

  bool get isZero => kobo == 0;

  bool get isNegative => kobo < 0;

  Money abs() => Money.fromKobo(kobo.abs());

  Money operator +(Money other) => Money.fromKobo(kobo + other.kobo);

  Money operator -(Money other) => Money.fromKobo(kobo - other.kobo);

  Money operator -() => Money.fromKobo(-kobo);

  Money operator *(int factor) => Money.fromKobo(kobo * factor);

  bool operator <(Money other) => kobo < other.kobo;

  bool operator <=(Money other) => kobo <= other.kobo;

  bool operator >(Money other) => kobo > other.kobo;

  bool operator >=(Money other) => kobo >= other.kobo;

  /// Renders as ₦2,480,000.00. Never divides, so no double is involved.
  String format({bool withSymbol = true}) {
    final magnitude = kobo.abs();
    final naira = _grouping.format(magnitude ~/ 100);
    final remainder = (magnitude % 100).toString().padLeft(2, '0');
    final sign = kobo < 0 ? '-' : '';
    final symbol = withSymbol ? '₦' : '';
    return '$sign$symbol$naira.$remainder';
  }

  @override
  int compareTo(Money other) => kobo.compareTo(other.kobo);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Money && other.kobo == kobo);

  @override
  int get hashCode => kobo.hashCode;

  @override
  String toString() => 'Money(${format()})';
}

/// Sums exactly, so no caller reaches for fold with a double accumulator.
Money sumMoney(Iterable<Money> amounts) {
  var total = 0;
  for (final amount in amounts) {
    total += amount.kobo;
  }
  return Money.fromKobo(total);
}

/// What may actually be spent. Defined once, because a second copy of this
/// subtraction is how two screens start disagreeing about the same wallet.
Money availableBalance({required Money confirmed, required Money pending}) =>
    Money.fromKobo(confirmed.kobo - pending.kobo);

/// Throws rather than coercing, since jsonDecode returns `num`.
int koboFromJson(Object? value) {
  if (value is int) return value;
  throw FormatException(
    'kobo must be an integer, got ${value.runtimeType}',
    value,
  );
}

/// Largest numerator that cannot overflow when scaled by [_basisPointScale].
const int _bpSafeLimit = 922337203685477;
const int _basisPointScale = 10000;

/// Progress in basis points, 0 to 10000. Truncates, never rounds up.
int progressBasisPoints({required Money saved, required Money target}) {
  if (target.kobo <= 0 || saved.kobo <= 0) return 0;
  if (saved.kobo >= target.kobo) return _basisPointScale;

  // saved * 10000 overflows a 64-bit int near the top of the range.
  var numerator = saved.kobo;
  var denominator = target.kobo;
  while (numerator > _bpSafeLimit) {
    numerator ~/= 10;
    denominator ~/= 10;
    if (denominator == 0) return _basisPointScale;
  }

  final basisPoints = (numerator * _basisPointScale) ~/ denominator;
  return basisPoints.clamp(0, _basisPointScale);
}

/// The whole-percent figure printed beside a progress bar.
int progressPercent({required Money saved, required Money target}) =>
    progressBasisPoints(saved: saved, target: target) ~/ 100;
