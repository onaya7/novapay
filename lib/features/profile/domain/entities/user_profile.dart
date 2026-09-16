import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/extensions/string_extension.dart';

part 'user_profile.freezed.dart';

/// Who is using this device. There is no auth, so this is local and the
/// customer's own — nothing here is claimed to have come from a server.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({@Default('') String displayName}) = _UserProfile;

  const UserProfile._();

  bool get hasName => displayName.trim().isNotEmpty;

  /// What the wallet greets. Falls back to the surface rather than a made-up
  /// name when nothing has been set.
  String get greetingName => hasName ? displayName.trim() : 'Wallet';

  String get initials => hasName ? displayName.initials : '?';
}
