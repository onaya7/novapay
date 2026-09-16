import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/exception/app_exceptions.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_service.dart';
import 'package:novapay/features/funding/domain/repositories/funding_repository.dart';
import 'package:novapay/server/novapay_api.dart';
import 'package:novapay/utils/either_safe_runner.dart';

@LazySingleton(as: FundingRepository)
class FundingRepositoryImpl implements FundingRepository {
  const FundingRepositoryImpl(this._api, this._sync, this._runner);

  final NovaPayApi _api;
  final SyncService _sync;
  final EitherSafeRunner _runner;

  @override
  Future<Either<Failure, Money>> balance() =>
      _runner(safeCallback: () async => _balance());

  /// There is no funds check here: money is arriving, so there is nothing to
  /// be short of.
  @override
  Future<Either<Failure, Unit>> addMoney(Money amount) => _runner(
    safeCallback: () async {
      if (amount.kobo <= 0) {
        throw const AppException.server('Enter an amount greater than zero');
      }
      await _sync.enqueue(
        type: PendingActionType.fund,
        amountKobo: amount.kobo,
        payload: const {},
      );
      return unit;
    },
  );

  Money _balance() {
    final response = _api.balance();
    if (!response.isSuccess) throw AppException.server(response.message);
    return Money.fromKobo(response.requireData);
  }
}
