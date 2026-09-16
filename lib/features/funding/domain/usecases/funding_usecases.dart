import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/funding/domain/repositories/funding_repository.dart';

@lazySingleton
class LoadWalletBalance implements UseCase<Money, NoParams> {
  const LoadWalletBalance(this._repository);

  final FundingRepository _repository;

  @override
  Future<Either<Failure, Money>> call(NoParams params) => _repository.balance();
}

@lazySingleton
class AddMoney implements UseCase<Unit, Money> {
  const AddMoney(this._repository);

  final FundingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(Money params) =>
      _repository.addMoney(params);
}
