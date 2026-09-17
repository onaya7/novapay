import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank.freezed.dart';

/// A recipient bank, picked before an account number. `logoAsset` is a
/// `flutter_gen` asset key, not a path string; null falls back to initials.
@freezed
abstract class Bank with _$Bank {
  const factory Bank({
    required String code,
    required String name,
    String? logoAsset,
  }) = _Bank;
}
