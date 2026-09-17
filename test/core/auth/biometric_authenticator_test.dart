import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/auth/biometric_authenticator.dart';

class _MockLocalAuthentication extends Mock implements LocalAuthentication;

void main() {
  late _MockLocalAuthentication localAuth;
  late LocalAuthBiometricAuthenticator authenticator;

  setUpAll(() {
    registerFallbackValue(const AuthenticationOptions());
  });

  setUp(() {
    localAuth = _MockLocalAuthentication();
    authenticator = LocalAuthBiometricAuthenticator(localAuth: localAuth);
  });

  test('an unsupported device never reaches authenticate', () async {
    when(localAuth.isDeviceSupported).thenAnswer((_) async => false);

    final result = await authenticator.authenticate();

    expect(result, isFalse);
    verifyNever(
      () => localAuth.authenticate(
        localizedReason: any(named: 'localizedReason'),
        options: any(named: 'options'),
      ),
    );
  });

  test('a supported device that confirms returns true', () async {
    when(localAuth.isDeviceSupported).thenAnswer((_) async => true);
    when(
      () => localAuth.authenticate(
        localizedReason: any(named: 'localizedReason'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => true);

    final result = await authenticator.authenticate();

    expect(result, isTrue);
  });

  test('a cancelled or refused prompt returns false', () async {
    when(localAuth.isDeviceSupported).thenAnswer((_) async => true);
    when(
      () => localAuth.authenticate(
        localizedReason: any(named: 'localizedReason'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => false);

    final result = await authenticator.authenticate();

    expect(result, isFalse);
  });

  test(
    'a PlatformException (not enrolled, locked out, ...) returns false',
    () async {
      when(localAuth.isDeviceSupported).thenAnswer((_) async => true);
      when(
        () => localAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenThrow(PlatformException(code: 'NotEnrolled'));

      final result = await authenticator.authenticate();

      expect(result, isFalse);
    },
  );

  test('the default constructor falls back to a real LocalAuthentication', () {
    expect(LocalAuthBiometricAuthenticator(), isA<BiometricAuthenticator>());
  });
}
