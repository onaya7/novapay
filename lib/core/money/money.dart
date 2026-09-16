import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

/// An exact amount of Nigerian currency, held as a whole number of kobo.
///
/// Naira never exists as a number anywhere in this app. It exists only as a
/// string produced by [format]. Every arithmetic operation here is integer
/// arithmetic, so no value can drift.
@immutable
class Money implements Comparable<Money> {
  const Money.fromKobo(this.kobo);

  /// Parses user or wire input, throwing [FormatException] when it is not a
  /// valid amount. See [tryParse] for the accepted shapes.
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

  /// The largest amount this app will accept.
  ///
  /// On the web target a Dart `int` is a 53-bit double, so integer semantics
  /// are exact only below 2^53. Bounding input here keeps every target
  /// identical rather than exact on some and lossy on others.
  static const int maxKobo = 9007199254740991;

  static final NumberFormat _grouping = NumberFormat.decimalPattern();

  /// Returns null rather than throwing when [input] is not a valid amount.
  ///
  /// Deliberately never builds a double. `(double.parse('0.29') * 100).toInt()`
  /// is 28, not 29, which loses a kobo on ordinary amounts. The fraction is
  /// taken as text and the whole value is parsed as a single integer.
  ///
  /// Accepts a leading minus, a naira sign, grouping commas and spaces. A
  /// fraction shorter than two digits is padded; one longer is truncated,
  /// never rounded, so no amount is ever rounded up.
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

  /// Renders the amount for display, for example `₦2,480,000.00`.
  ///
  /// Never divides. The naira and kobo halves are taken with `~/` and `%` and
  /// joined as text, so the value cannot pass through a double on its way to
  /// the screen. `NumberFormat.currency` is deliberately not used: it takes a
  /// `num` and routes through a double internally.
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

/// Sums [amounts] exactly. Present so no caller reaches for `fold` with a
/// double accumulator.
Money sumMoney(Iterable<Money> amounts) {
  var total = 0;
  for (final amount in amounts) {
    total += amount.kobo;
  }
  return Money.fromKobo(total);
}

/// Reads a kobo value off decoded JSON, throwing rather than coercing.
///
/// `jsonDecode` returns `num`, so a value that has ever passed through a
/// double arrives as `1000.0`. Coercing it with `.toInt()` would silently
/// truncate money, so this refuses instead.
int koboFromJson(Object? value) {
  if (value is int) return value;
  throw FormatException(
    'kobo must be an integer, got ${value.runtimeType}',
    value,
  );
}

/// Largest numerator that cannot overflow a 64-bit int when multiplied by
/// [_basisPointScale].
const int _bpSafeLimit = 922337203685477;
const int _basisPointScale = 10000;

/// Progress toward a savings goal, in basis points from 0 to 10000.
///
/// Integer throughout. A double appears only where the caller hands this to a
/// progress bar, and that boundary is one way: nothing reads the double back
/// to build a label.
///
/// Truncates rather than rounds, so a goal that is 99.99 per cent funded does
/// not read as complete.
int progressBasisPoints({required Money saved, required Money target}) {
  if (target.kobo <= 0 || saved.kobo <= 0) return 0;
  if (saved.kobo >= target.kobo) return _basisPointScale;

  // saved * 10000 overflows a 64-bit int near the top of the exact range, so
  // scale both sides down before multiplying rather than after.
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
///
/// Always shown as text next to the bar, which is what makes the bar's own
/// contrast acceptable: the value is never carried by color alone.
int progressPercent({required Money saved, required Money target}) =>
    progressBasisPoints(saved: saved, target: target) ~/ 100;
