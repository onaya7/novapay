import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/domain/repositories/wallet_repository.dart';

@lazySingleton
class LoadWallet implements UseCase<WalletSnapshot, NoParams> {
  const LoadWallet(this._repository);

  final WalletRepository _repository;

  @override
  Future<Either<Failure, WalletSnapshot>> call(NoParams params) =>
      _repository.load();
}
