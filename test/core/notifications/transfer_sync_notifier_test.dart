import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/notifications/notification_service.dart';
import 'package:novapay/core/notifications/transfer_sync_notifier.dart';
import 'package:novapay/core/sync/pending_action.dart';
import 'package:novapay/core/sync/sync_service.dart';

class _MockSyncService extends Mock implements SyncService;

class _MockNotificationService extends Mock implements NotificationService;

PendingAction _action({
  String id = 'a1',
  PendingActionType type = PendingActionType.send,
  PendingActionStatus status = PendingActionStatus.done,
  int amountKobo = 500000,
}) => PendingAction(
  id: id,
  type: type,
  amountKobo: amountKobo,
  payload: const {'recipient': '0123456789'},
  createdAt: DateTime.utc(2026, 9, 16, 12),
  status: status,
);

void main() {
  late _MockSyncService sync;
  late _MockNotificationService notifications;
  late StreamController<List<PendingAction>> changes;
  late TransferSyncNotifier notifier;

  setUp(() {
    sync = _MockSyncService();
    notifications = _MockNotificationService();
    changes = StreamController<List<PendingAction>>.broadcast();
    when(() => sync.changes).thenAnswer((_) => changes.stream);
    when(
      () => notifications.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {});
    notifier = TransferSyncNotifier(sync, notifications);
  });

  tearDown(() => changes.close());

  test('a send newly settled fires exactly one notification', () async {
    when(() => sync.actions())
        .thenReturn([_action(status: PendingActionStatus.queued)]);
    await notifier.start();

    changes.add([_action()]);
    await Future<void>.delayed(Duration.zero);

    verify(
      () => notifications.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).called(1);
  });

  test('already-settled sends at start-up never notify', () async {
    when(() => sync.actions()).thenReturn([_action()]);
    await notifier.start();

    changes.add([_action()]);
    await Future<void>.delayed(Duration.zero);

    verifyNever(
      () => notifications.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    );
  });

  test('a settled contribution or top-up is silent', () async {
    when(() => sync.actions()).thenReturn([]);
    await notifier.start();

    changes.add([
      _action(id: 'c1', type: PendingActionType.contribute),
      _action(id: 'f1', type: PendingActionType.fund),
    ]);
    await Future<void>.delayed(Duration.zero);

    verifyNever(
      () => notifications.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    );
  });

  test('the same settled send is never notified twice', () async {
    when(() => sync.actions()).thenReturn([]);
    await notifier.start();

    changes
      ..add([_action()])
      ..add([_action()]);
    await Future<void>.delayed(Duration.zero);

    verify(
      () => notifications.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).called(1);
  });

  test('dispose stops listening', () async {
    when(() => sync.actions()).thenReturn([]);
    await notifier.start();
    await notifier.dispose();

    changes.add([_action()]);
    await Future<void>.delayed(Duration.zero);

    verifyNever(
      () => notifications.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    );
  });
}
