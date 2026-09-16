import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/send_money/domain/repositories/transfer_repository.dart';

@lazySingleton
class LoadAvailable implements UseCase<Money, NoParams> {
  const LoadAvailable(this._repository);

  final TransferRepository _repository;

  @override
  Future<Either<Failure, Money>> call(NoParams params) =>
      _repository.available();
}
