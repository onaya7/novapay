import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/notifications/notification_service.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_service.dart';

/// Watches the offline queue and notifies once per **send** that finishes
/// syncing, so the customer learns a transfer went through even if the app is
/// backgrounded when it happens. Contributions and top-ups are deliberately
/// silent — the brief only asks for a queued send.
@lazySingleton
class TransferSyncNotifier {
  TransferSyncNotifier(this._sync, this._notifications);

  final SyncService _sync;
  final NotificationService _notifications;

  StreamSubscription<List<PendingAction>>? _subscription;

  /// Already-`done` ids at the moment this starts, so a cold start over an
  /// already-synced queue never re-notifies for old news.
  late Set<String> _notified;

  Future<void> start() async {
    _notified = _doneSendIds(_sync.actions());
    _subscription ??= _sync.changes.listen(_onChange);
  }

  void _onChange(List<PendingAction> actions) {
    for (final id in _doneSendIds(actions)) {
      if (!_notified.add(id)) continue;
      final action = actions.firstWhere((a) => a.id == id);
      unawaited(
        _notifications.show(
          title: 'Transfer sent',
          body: '${Money.fromKobo(action.amountKobo).format()} is on its way.',
        ),
      );
    }
  }

  Set<String> _doneSendIds(List<PendingAction> actions) => {
    for (final action in actions)
      if (action.type == PendingActionType.send &&
          action.status == PendingActionStatus.done)
        action.id,
  };

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
