part of 'wallet_cubit.dart';

@freezed
sealed class WalletState with _$WalletState {
  const factory WalletState.loading() = WalletLoading;
  const factory WalletState.ready(WalletSnapshot snapshot) = WalletReady;
  const factory WalletState.failure(String message) = WalletFailure;
}
