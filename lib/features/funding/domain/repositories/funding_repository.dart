import 'package:dartz/dartz.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';

abstract class FundingRepository {
  Future<Either<Failure, Money>> balance();

  /// Queued, not sent: money arriving must survive being offline too.
  Future<Either<Failure, Unit>> addMoney(Money amount);
}
