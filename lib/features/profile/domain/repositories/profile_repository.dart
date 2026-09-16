import 'package:dartz/dartz.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> load();

  Future<Either<Failure, UserProfile>> saveDisplayName(String name);
}
