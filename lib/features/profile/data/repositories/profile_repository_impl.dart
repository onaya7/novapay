import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/constants/storage_keys.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/features/profile/domain/entities/user_profile.dart';
import 'package:novapay/features/profile/domain/repositories/profile_repository.dart';
import 'package:novapay/utils/either_safe_runner.dart';

/// Local only. There is no auth, so nothing here leaves the device and none of
/// it is presented as coming from a server.
@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._storage, this._runner);

  final LocalDataStorage _storage;
  final EitherSafeRunner _runner;

  @override
  Future<Either<Failure, UserProfile>> load() =>
      _runner(safeCallback: () async => _read());

  @override
  Future<Either<Failure, UserProfile>> saveDisplayName(String name) => _runner(
    safeCallback: () async {
      await _storage.write<String>(StorageKeys.displayName, name.trim());
      return _read();
    },
  );

  UserProfile _read() => UserProfile(
    displayName: _storage.read<String>(StorageKeys.displayName) ?? '',
  );
}
