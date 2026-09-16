import 'package:novapay/core/money/money.dart';

extension IntX on int {
  /// Reads an integer as an amount of kobo: `500000.kobo`.
  Money get kobo => Money.fromKobo(this);

  /// Reads whole naira as kobo, without ever touching a double.
  Money get naira => Money.fromKobo(this * 100);

  /// `1` becomes `1st`, for "3rd attempt" style copy.
  String get ordinal {
    final lastTwo = abs() % 100;
    if (lastTwo >= 11 && lastTwo <= 13) return '${this}th';
    return switch (abs() % 10) {
      1 => '${this}st',
      2 => '${this}nd',
      3 => '${this}rd',
      _ => '${this}th',
    };
  }
}
