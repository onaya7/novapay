import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// For tokens and passwords use `SecureLocalDataStorage`.
abstract class LocalDataStorage {
  T? read<T>(String key, {T? defaultValue});
  Future<void> write<T>(String key, T value);
  Future<void> delete(String key);
  Future<void> clear();
}

@LazySingleton(as: LocalDataStorage)
class LocalDataStorageImpl implements LocalDataStorage {
  LocalDataStorageImpl(this._box);

  final Box<dynamic> _box;

  @override
  T? read<T>(String key, {T? defaultValue}) {
    final value = _box.get(key, defaultValue: defaultValue);
    if (value is T) return value;
    return defaultValue;
  }

  @override
  Future<void> write<T>(String key, T value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> clear() => _box.clear().then((_) {});
}
