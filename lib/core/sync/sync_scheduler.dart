import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:novapay/core/network_info/network_info.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_service.dart';
import 'package:novapay/core/time/clock.dart';

/// Wakes the queue on its own: when the network returns, and when a backed-off
/// action falls due.
@lazySingleton
class SyncScheduler {
  SyncScheduler(this._sync, this._networkInfo, this._clock);

  final SyncService _sync;
  final NetworkInfo _networkInfo;
  final Clock _clock;

  StreamSubscription<bool>? _connectivity;
  StreamSubscription<List<PendingAction>>? _queue;
  Timer? _backoff;

  Future<void> start() async {
    if (_connectivity != null) return;
    _connectivity = _networkInfo.onConnectivityChanged
        .where((connected) => connected)
        .listen((_) => unawaited(_drain()));
    _queue = _sync.changes.listen(_rearm);
    await _sync.recoverInterrupted();
    // Seeded here too: a backoff persisted across a kill emits no change
    // event, so the subscription alone would never arm the timer.
    _rearm(_sync.actions());
    unawaited(_drain());
  }

  void _rearm(List<PendingAction> actions) {
    _backoff?.cancel();
    _backoff = null;
    final now = _clock.now();
    DateTime? earliest;
    for (final action in actions) {
      final due = action.nextAttemptAt;
      if (!action.status.isPending || due == null || !due.isAfter(now)) {
        continue;
      }
      if (earliest == null || due.isBefore(earliest)) earliest = due;
    }
    if (earliest == null) return;
    _backoff = Timer(earliest.difference(now), () => unawaited(_drain()));
  }

  Future<void> _drain() async {
    try {
      await _sync.drain();
    } on Object {
      // A throwing drain must not take the subscription down with it.
      return;
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    _backoff?.cancel();
    _backoff = null;
    await _connectivity?.cancel();
    await _queue?.cancel();
    _connectivity = null;
    _queue = null;
  }
}
