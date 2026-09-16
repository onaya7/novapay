import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:novapay/core/constants/storage_keys.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/core/network_info/network_info.dart';
import 'package:novapay/core/sync/pending_action.dart';
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

  /// Saves the action, then tries to send it straight away.
  Future<PendingAction> enqueue({
    required PendingActionType type,
    required int amountKobo,
    required Map<String, dynamic> payload,
  });

  /// Puts anything interrupted mid-send back in the queue. Call at startup.
  Future<void> recoverInterrupted();

  /// Sends everything queued. Does nothing without a network.
  Future<void> drain();

  /// Total still owed, so the wallet can show committed but unsettled money.
  int pendingKobo();

  Future<void> clearFinished();

  Future<void> dispose();
}

@LazySingleton(as: SyncService)
class SyncServiceImpl implements SyncService {
  SyncServiceImpl(this._db, this._api, this._networkInfo, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final LocalDataStorage _db;
  final NovaPayApi _api;
  final NetworkInfo _networkInfo;
  final Uuid _uuid;

  final _changes = StreamController<List<PendingAction>>.broadcast();

  /// Serializes drains. A bool guard would make a drain requested mid-drain a
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
      createdAt: DateTime.now(),
    );
    await _save([...actions(), action]);
    unawaited(drain());
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
      if (recovered.status != all[i].status) {
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

  Future<void> _drainOnce() async {
    if (!await _networkInfo.isConnected) return;
    for (final action in pending()) {
      await _send(action);
    }
  }

  Future<void> _send(PendingAction action) async {
    await _replace(action.sending());
    try {
      final response = switch (action.type) {
        PendingActionType.send => await _api.transfer(
          idempotencyKey: action.id,
          recipient: action.payload['recipient'] as String,
          amountKobo: action.amountKobo,
        ),
        PendingActionType.contribute => await _api.contribute(
          idempotencyKey: action.id,
          goalId: action.payload['goalId'] as String,
          amountKobo: action.amountKobo,
        ),
      };
      await _replace(
        response.isSuccess ? action.succeeded() : action.failedAttempt(),
      );
    } on Object {
      // Only a transport failure reaches here; a refusal came back as a
      // response above.
      await _replace(action.failedAttempt());
    }
  }

  @override
  int pendingKobo() =>
      pending().fold(0, (sum, action) => sum + action.amountKobo);

  @override
  Future<void> clearFinished() async {
    await _save(actions().where((a) => a.status.isPending).toList());
  }

  @override
  @disposeMethod
  Future<void> dispose() => _changes.close();
}
