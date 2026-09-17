import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/send_money/domain/entities/bank.dart';
import 'package:novapay/features/send_money/domain/repositories/bank_repository.dart';

@injectable
class LoadBanks implements UseCase<List<Bank>, NoParams> {
  const LoadBanks(this._repository);

  final BankRepository _repository;

  @override
  Future<Either<Failure, List<Bank>>> call(NoParams params) async =>
      Right(_repository.banks());
}
