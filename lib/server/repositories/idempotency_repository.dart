import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';

/// Every idempotency key the server has already applied.
///
/// This is persisted rather than held in memory, because the replay it has to
/// recognise usually arrives after the app was killed and restarted.
abstract class IdempotencyRepository {
  bool hasSeen(String idempotencyKey);
  Future<void> record(String idempotencyKey);
  Future<void> clear();
}

@LazySingleton(as: IdempotencyRepository)
class IdempotencyRepositoryImpl implements IdempotencyRepository {
  IdempotencyRepositoryImpl(this._db);

  final LocalDataStorage _db;

  static const String _key = 'server_applied_keys';

  Set<String> _all() {
    final raw = _db.read<String>(_key);
    if (raw == null) return <String>{};
    return (jsonDecode(raw) as List).cast<String>().toSet();
  }

  @override
  bool hasSeen(String idempotencyKey) => _all().contains(idempotencyKey);

  @override
  Future<void> record(String idempotencyKey) async {
    final keys = _all()..add(idempotencyKey);
    await _db.write<String>(_key, jsonEncode(keys.toList()));
  }

  @override
  Future<void> clear() => _db.delete(_key);
}
