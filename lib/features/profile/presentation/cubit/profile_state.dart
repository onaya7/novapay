part of 'profile_cubit.dart';

@freezed
sealed class ProfileState with _$ProfileState {
  const factory ProfileState.loading() = ProfileLoading;
  const factory ProfileState.ready(UserProfile profile) = ProfileReady;
  const factory ProfileState.failure(String message) = ProfileFailure;

  const ProfileState._();

  /// Empty until it has loaded, so the greeting falls back rather than
  /// flashing a name in and out. `ready` declares `profile` as a field, which
  /// overrides this.
  UserProfile get profile => const UserProfile();
}
