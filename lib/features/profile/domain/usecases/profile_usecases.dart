import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/profile/domain/entities/user_profile.dart';
import 'package:novapay/features/profile/domain/repositories/profile_repository.dart';

@lazySingleton
class LoadProfile implements UseCase<UserProfile, NoParams> {
  const LoadProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, UserProfile>> call(NoParams params) =>
      _repository.load();
}

@lazySingleton
class SaveDisplayName implements UseCase<UserProfile, String> {
  const SaveDisplayName(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, UserProfile>> call(String params) =>
      _repository.saveDisplayName(params);
}
