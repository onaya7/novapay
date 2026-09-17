import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

/// Screens depend on this, not `LocalAuthentication`, so a confirm flow can
/// be tested without a platform channel.
abstract class BiometricAuthenticator {
  Future<bool> authenticate();
}

@LazySingleton(as: BiometricAuthenticator)
class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  LocalAuthBiometricAuthenticator({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  @override
  Future<bool> authenticate() async {
    // Covers PIN/pattern fallback too, not just biometrics.
    if (!await _localAuth.isDeviceSupported()) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: 'Confirm your identity to send this transfer.',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException {
      // Cancelled, not enrolled, locked out — all mean "not confirmed".
      return false;
    }
  }
}
