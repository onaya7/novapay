import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Keychain and Keystore storage for tokens and other secrets.
abstract class SecureLocalDataStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

@LazySingleton(as: SecureLocalDataStorage)
class SecureLocalDataStorageImpl implements SecureLocalDataStorage {
  SecureLocalDataStorageImpl(this._storage);

  final FlutterSecureStorage _storage;

  // v11 defaults to AES-GCM with RSA-OAEP key wrapping; the old
  // encryptedSharedPreferences flag was removed because it is now the default.
  static const AndroidOptions _androidOptions = AndroidOptions.defaultOptions;
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  @override
  Future<String?> read(String key) =>
      _storage.read(key: key, aOptions: _androidOptions, iOptions: _iosOptions);

  @override
  Future<void> write(String key, String value) => _storage.write(
    key: key,
    value: value,
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  @override
  Future<void> delete(String key) => _storage.delete(
    key: key,
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  @override
  Future<void> deleteAll() =>
      _storage.deleteAll(aOptions: _androidOptions, iOptions: _iosOptions);
}
