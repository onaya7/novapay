import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_receipt.dart';
import 'package:novapay/features/send_money/domain/repositories/transfer_repository.dart';

class TransferParams extends Equatable {
  const TransferParams({required this.recipient, required this.amount});

  final String recipient;
  final Money amount;

  @override
  List<Object?> get props => [recipient, amount];
}

@lazySingleton
class QueueTransfer implements UseCase<TransferReceipt, TransferParams> {
  const QueueTransfer(this._repository);

  final TransferRepository _repository;

  @override
  Future<Either<Failure, TransferReceipt>> call(TransferParams params) =>
      _repository.queue(recipient: params.recipient, amount: params.amount);
}
