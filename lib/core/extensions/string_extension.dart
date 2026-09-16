import 'package:novapay/core/money/money.dart';

extension StringX on String {
  /// True for a NUBAN account number: exactly ten digits.
  bool get isAccountNumber =>
      length == 10 && codeUnits.every((c) => c >= 0x30 && c <= 0x39);

  /// `0123456789` becomes `•••••• 6789`, the way a statement shows it.
  String get maskedAccountNumber {
    if (length <= 4) return this;
    return '${'•' * (length - 4)} ${substring(length - 4)}';
  }

  /// Up to two initials for an avatar. Empty input gives `?` rather than a
  /// blank circle.
  String get initials {
    final words = trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Parses an amount a customer typed, or null when it is not one.
  Money? get asMoney => Money.tryParse(this);

  /// For a label that must not be blank.
  String orIfBlank(String fallback) => trim().isEmpty ? fallback : this;
}
