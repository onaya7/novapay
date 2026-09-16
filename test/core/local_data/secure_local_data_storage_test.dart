import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/local_data/secure_local_data_storage.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage;

void main() {
  late _MockSecureStorage inner;
  late SecureLocalDataStorage storage;

  setUp(() {
    inner = _MockSecureStorage();
    storage = SecureLocalDataStorageImpl(inner);
  });

  test('read returns the stored secret', () async {
    when(
      () => inner.read(
        key: any(named: 'key'),
        aOptions: any(named: 'aOptions'),
        iOptions: any(named: 'iOptions'),
      ),
    ).thenAnswer((_) async => 'token');
    expect(await storage.read('auth_token'), 'token');
  });

  test('read returns null when nothing is stored', () async {
    when(
      () => inner.read(
        key: any(named: 'key'),
        aOptions: any(named: 'aOptions'),
        iOptions: any(named: 'iOptions'),
      ),
    ).thenAnswer((_) async => null);
    expect(await storage.read('missing'), isNull);
  });

  test('write passes platform options through', () async {
    when(
      () => inner.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
        aOptions: any(named: 'aOptions'),
        iOptions: any(named: 'iOptions'),
      ),
    ).thenAnswer((_) async {});
    await storage.write('auth_token', 'abc');
    final call = verify(
      () => inner.write(
        key: 'auth_token',
        value: 'abc',
        aOptions: any(named: 'aOptions'),
        iOptions: captureAny(named: 'iOptions'),
      ),
    )..called(1);
    final options = call.captured.single as IOSOptions;
    expect(options.accessibility, KeychainAccessibility.first_unlock);
  });

  test('delete removes one key', () async {
    when(
      () => inner.delete(
        key: any(named: 'key'),
        aOptions: any(named: 'aOptions'),
        iOptions: any(named: 'iOptions'),
      ),
    ).thenAnswer((_) async {});
    await storage.delete('auth_token');
    verify(
      () => inner.delete(
        key: 'auth_token',
        aOptions: any(named: 'aOptions'),
        iOptions: any(named: 'iOptions'),
      ),
    ).called(1);
  });

  test('deleteAll clears every secret', () async {
    when(
      () => inner.deleteAll(
        aOptions: any(named: 'aOptions'),
        iOptions: any(named: 'iOptions'),
      ),
    ).thenAnswer((_) async {});
    await storage.deleteAll();
    verify(
      () => inner.deleteAll(
        aOptions: any(named: 'aOptions'),
        iOptions: any(named: 'iOptions'),
      ),
    ).called(1);
  });
}
