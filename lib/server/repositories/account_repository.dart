import 'package:injectable/injectable.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';

/// The wallet balance, in kobo.
abstract class AccountRepository {
  /// What a new install starts with, so the app has something to show.
  static const int openingBalanceKobo = 24800000;

  int balanceKobo();
  Future<void> setBalanceKobo(int value);
  Future<void> clear();
}

@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._db);

  final LocalDataStorage _db;

  static const String _key = 'server_balance_kobo';

  @override
  int balanceKobo() =>
      _db.read<int>(_key, defaultValue: AccountRepository.openingBalanceKobo) ??
      AccountRepository.openingBalanceKobo;

  @override
  Future<void> setBalanceKobo(int value) => _db.write<int>(_key, value);

  @override
  Future<void> clear() => _db.delete(_key);
}
