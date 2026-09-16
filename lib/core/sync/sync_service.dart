import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:novapay/core/constants/storage_keys.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/core/network_info/network_info.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/time/clock.dart';
import 'package:novapay/server/models/api_response.dart';
import 'package:novapay/server/novapay_api.dart';
import 'package:uuid/uuid.dart';

/// The local queue of money actions: written to the database before anything
/// is sent, then drained when there is a network.
///
/// Screens depend on this rather than on the implementation, so a cubit can be
/// tested against a stub queue without Hive or a server.
abstract class SyncService {
  /// Emits the whole queue whenever it changes, for the UI to render.
  Stream<List<PendingAction>> get changes;

  /// Everything in the queue, settled or not.
  List<PendingAction> actions();

  /// Just what still owes an outcome, oldest first.
  List<PendingAction> pending();

  /// Anything that ended without a readable answer and needs a decision.
  List<PendingAction> unresolved();

  /// Saves the action, then tries to send it straight away.
  Future<PendingAction> enqueue({
    required PendingActionType type,
    required int amountKobo,
    required Map<String, dynamic> payload,
  });

  /// Puts anything interrupted mid-send back in the queue. Call at startup.
  Future<void> recoverInterrupted();

  /// Sends everything runnable. Does nothing without a network.
  Future<void> drain();

  /// Money the customer cannot spend: still owed, or possibly already gone.
  int pendingKobo();

  Future<void> clearFinished();

  Future<void> dispose();
}

@LazySingleton(as: SyncService)
class SyncServiceImpl implements SyncService {
  SyncServiceImpl(
    this._db,
    this._api,
    this._networkInfo,
    this._clock, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final LocalDataStorage _db;
  final NovaPayApi _api;
  final NetworkInfo _networkInfo;
  final Clock _clock;
  final Uuid _uuid;

  final _changes = StreamController<List<PendingAction>>.broadcast();

  /// Serialises drains. A bool guard would make a drain requested mid-drain a
  /// silent no-op, which loses the wake-up when connectivity returns.
  Future<void> _lock = Future<void>.value();

  @override
  Stream<List<PendingAction>> get changes => _changes.stream;

  @override
  List<PendingAction> actions() {
    final raw = _db.read<String>(StorageKeys.pendingActions);
    if (raw == null) return [];
    final rows = jsonDecode(raw) as List;
    final result = <PendingAction>[];
    for (final row in rows) {
      try {
        result.add(PendingAction.fromStoredJson(row as Map<String, dynamic>));
      } on Object {
        // A row this build cannot read is dropped, so one bad entry never
        // strands the rest of the queue.
        continue;
      }
    }
    return result;
  }

  @override
  List<PendingAction> pending() =>
      actions().where((action) => action.status.isPending).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  List<PendingAction> unresolved() => actions()
      .where((action) => action.status == PendingActionStatus.unresolved)
      .toList();

  Future<void> _save(List<PendingAction> actions) async {
    await _db.write<String>(
      StorageKeys.pendingActions,
      jsonEncode(actions.map((action) => action.toJson()).toList()),
    );
    _changes.add(actions);
  }

  Future<void> _replace(PendingAction action) async {
    final all = actions();
    final index = all.indexWhere((a) => a.id == action.id);
    if (index < 0) return;
    all[index] = action;
    await _save(all);
  }

  /// Writes the action to the database first, so it survives being offline or
  /// force-quit, then tries to send it straight away.
  @override
  Future<PendingAction> enqueue({
    required PendingActionType type,
    required int amountKobo,
    required Map<String, dynamic> payload,
  }) async {
    final action = PendingAction(
      id: _uuid.v4(),
      type: type,
      amountKobo: amountKobo,
      payload: payload,
      createdAt: _clock.now(),
    );
    await _save([...actions(), action]);
    // Awaited, not fire-and-forget: a caller that also drained would otherwise
    // spend two of the attempts on one action.
    await drain();
    return action;
  }

  /// Safe because the id is the idempotency key, so a resend is collapsed by
  /// the backend rather than moving money twice.
  @override
  Future<void> recoverInterrupted() async {
    final all = actions();
    var changed = false;
    for (var i = 0; i < all.length; i++) {
      final recovered = all[i].recovered();
      if (recovered != all[i]) {
        all[i] = recovered;
        changed = true;
      }
    }
    if (changed) await _save(all);
  }

  @override
  Future<void> drain() {
    final next = _lock.then((_) => _drainOnce());
    _lock = next.catchError((Object _) {});
    return next;
  }

  /// Drains the oldest *runnable* action, not simply the oldest: one sitting
  /// inside its backoff window must not block the rest of the queue.
  Future<void> _drainOnce() async {
    if (!await _networkInfo.isConnected) return;
    final now = _clock.now();
    for (final action in pending()) {
      if (!action.isRunnableAt(now)) continue;
      await _send(action);
    }
  }

  Future<void> _send(PendingAction action) async {
    final attempt = action.sending(_uuid.v4());
    await _replace(attempt);
    try {
      final response = switch (attempt.type) {
        PendingActionType.send => await _api.transfer(
          idempotencyKey: attempt.id,
          recipient: attempt.payload['recipient'] as String,
          amountKobo: attempt.amountKobo,
        ),
        PendingActionType.contribute => await _api.contribute(
          idempotencyKey: attempt.id,
          goalId: attempt.payload['goalId'] as String,
          amountKobo: attempt.amountKobo,
        ),
      };
      await _replace(_settle(attempt, response));
    } on Object {
      // Only a transport failure reaches here. It was transmitted, so it may
      // have been processed; that is not the same as knowing it was not.
      await _replace(attempt.ambiguousAttempt(_clock.now()));
    }
  }

  /// An answer is knowledge either way: a refusal is provably not processed,
  /// so it is terminal rather than retried.
  PendingAction _settle(PendingAction attempt, ApiResponse<Object?> response) =>
      response.isSuccess
      ? attempt.succeeded()
      : attempt.refused(response.message);

  @override
  int pendingKobo() => actions()
      .where((action) => action.status.holdsFunds)
      .fold(0, (sum, action) => sum + action.amountKobo);

  @override
  Future<void> clearFinished() async {
    await _save(actions().where((a) => !a.status.isTerminal).toList());
  }

  @override
  @disposeMethod
  Future<void> dispose() => _changes.close();
}
