import 'package:injectable/injectable.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/domain/repositories/wallet_repository.dart';

@lazySingleton
class WatchWallet implements StreamUseCase<WalletSnapshot, NoParams> {
  const WatchWallet(this._repository);

  final WalletRepository _repository;

  @override
  Stream<WalletSnapshot> call(NoParams params) => _repository.watch();
}
