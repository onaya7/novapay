import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/server/models/transaction.dart';

/// The settled ledger, newest first.
abstract class TransactionRepository {
  List<Transaction> findAll();
  Transaction? findById(String id);
  Future<void> insert(Transaction transaction);
  Future<void> clear();
}

@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._db);

  final LocalDataStorage _db;

  static const String _key = 'server_transactions';

  @override
  List<Transaction> findAll() {
    final raw = _db.read<String>(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((row) => Transaction.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Transaction? findById(String id) {
    for (final transaction in findAll()) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  @override
  Future<void> insert(Transaction transaction) async {
    final all = [transaction, ...findAll()];
    await _db.write<String>(
      _key,
      jsonEncode(all.map((t) => t.toJson()).toList()),
    );
  }

  @override
  Future<void> clear() => _db.delete(_key);
}
