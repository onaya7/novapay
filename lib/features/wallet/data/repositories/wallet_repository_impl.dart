import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/exception/app_exceptions.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_service.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:novapay/server/models/api_response.dart';
import 'package:novapay/server/models/transaction.dart';
import 'package:novapay/server/novapay_api.dart';
import 'package:novapay/utils/either_safe_runner.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._api, this._sync, this._runner);

  final NovaPayApi _api;
  final SyncService _sync;
  final EitherSafeRunner _runner;

  @override
  Future<Either<Failure, WalletSnapshot>> load() =>
      _runner(safeCallback: () async => _snapshot());

  @override
  Stream<WalletSnapshot> watch() => _sync.changes.map((_) => _snapshot());

  WalletSnapshot _snapshot() {
    return WalletSnapshot(
      confirmedKobo: _unwrap(_api.balance()),
      pendingKobo: _sync.pendingKobo(),
      activity: _activity(),
    );
  }

  List<ActivityItem> _activity() {
    final settled = _unwrap(_api.transactions());
    return <ActivityItem>[
      for (final action in _sync.actions())
        if (_queuedStatus(action.status) case final status?)
          _fromAction(action, status),
      for (final transaction in settled) _fromTransaction(transaction),
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  /// Translates the envelope into the app's error vocabulary; a refusal on a
  /// read is a failure the UI must show, not data.
  T _unwrap<T>(ApiResponse<T> response) {
    if (!response.isSuccess) throw AppException.server(response.message);
    return response.requireData;
  }

  ActivityItem _fromAction(PendingAction action, ActivityStatus status) =>
      ActivityItem(
        id: action.id,
        title: _titleFor(action),
        amountKobo: -action.amountKobo,
        occurredAt: action.createdAt,
        status: status,
        failureMessage: action.failureMessage,
      );

  /// Null once it has settled: the server owns it from then on, so it is
  /// listed from the ledger and dropping it here is what stops a double entry.
  ActivityStatus? _queuedStatus(PendingActionStatus status) => switch (status) {
    PendingActionStatus.queued ||
    PendingActionStatus.sending => ActivityStatus.pending,
    PendingActionStatus.rejected => ActivityStatus.rejected,
    PendingActionStatus.unresolved => ActivityStatus.unresolved,
    PendingActionStatus.done => null,
  };

  String _titleFor(PendingAction action) => switch (action.type) {
    PendingActionType.send =>
      'To ${action.payload['recipient'] ?? 'a NovaPay account'}',
    PendingActionType.contribute => 'Savings contribution',
  };

  ActivityItem _fromTransaction(Transaction transaction) => ActivityItem(
    id: transaction.id,
    title: transaction.title,
    amountKobo: transaction.amountKobo,
    occurredAt: transaction.occurredAt,
    status: ActivityStatus.settled,
  );
}
