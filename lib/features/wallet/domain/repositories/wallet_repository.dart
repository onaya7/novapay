import 'package:dartz/dartz.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';

abstract class WalletRepository {
  Future<Either<Failure, WalletSnapshot>> load();

  /// Re-emits whenever the queue changes, so a send shows as Pending at once.
  Stream<WalletSnapshot> watch();
}
