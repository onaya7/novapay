import 'package:dartz/dartz.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_receipt.dart';

abstract class TransferRepository {
  Future<Either<Failure, Money>> available();

  Future<Either<Failure, TransferReceipt>> queue({
    required String bankCode,
    required String bankName,
    required String recipient,
    required Money amount,
  });
}
