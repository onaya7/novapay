import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/sync/pending_action.dart';

PendingAction action({
  String id = 'a1',
  PendingActionStatus status = PendingActionStatus.queued,
  int amountKobo = 500000,
  int attemptCount = 0,
}) => PendingAction(
  id: id,
  type: PendingActionType.send,
  amountKobo: amountKobo,
  payload: const {'recipient': '0123456789'},
  createdAt: DateTime.utc(2026, 9, 16, 12),
  status: status,
  attemptCount: attemptCount,
);

void main() {
  group('status', () {
    test('queued and sending both show as Pending to the user', () {
      expect(PendingActionStatus.queued.isPending, isTrue);
      expect(PendingActionStatus.sending.isPending, isTrue);
      expect(PendingActionStatus.done.isPending, isFalse);
      expect(PendingActionStatus.failed.isPending, isFalse);
    });
  });

  group('transitions', () {
    test('sending does not spend an attempt', () {
      final sending = action().sending();
      expect(sending.status, PendingActionStatus.sending);
      expect(sending.attemptCount, 0);
    });

    test('success finishes it', () {
      final done = action(status: PendingActionStatus.sending).succeeded();
      expect(done.status, PendingActionStatus.done);
      expect(done.attemptCount, 1);
    });

    test('a failure requeues while there is budget left', () {
      final again = action(attemptCount: 1).failedAttempt();
      expect(again.status, PendingActionStatus.queued);
      expect(again.attemptCount, 2);
    });

    test('the queue gives up rather than spinning forever', () {
      final exhausted = action(attemptCount: kPendingActionMaxAttempts - 1)
          .failedAttempt();
      expect(exhausted.status, PendingActionStatus.failed);
      expect(exhausted.attemptCount, kPendingActionMaxAttempts);
    });

    test('a send interrupted by a crash goes back to the queue', () {
      // Safe to resend, because the id is the idempotency key.
      final stuck = action(status: PendingActionStatus.sending);
      expect(stuck.recovered().status, PendingActionStatus.queued);
      expect(stuck.recovered().attemptCount, 0);
    });

    test('recovery leaves every other state alone', () {
      for (final status in [
        PendingActionStatus.queued,
        PendingActionStatus.done,
        PendingActionStatus.failed,
      ]) {
        expect(action(status: status).recovered().status, status);
      }
    });

    test('copyWith keeps the fields it is not given', () {
      final bumped = action().copyWith(attemptCount: 3);
      expect(bumped.attemptCount, 3);
      expect(bumped.status, PendingActionStatus.queued);
      expect(
        action().copyWith(status: PendingActionStatus.done).attemptCount,
        0,
      );
    });

    test('the id never changes, so a retry cannot become a second send', () {
      var a = action();
      a = a.sending();
      a = a.failedAttempt();
      a = a.sending();
      a = a.succeeded();
      expect(a.id, 'a1');
      expect(a.status, PendingActionStatus.done);
      expect(a.attemptCount, 2);
    });
  });

  group('identity', () {
    test('compares by value across every field', () {
      expect(action(), action());
      expect(action().hashCode, action().hashCode);
      expect(action(id: 'a') == action(id: 'b'), isFalse);
      // Freezed equality is all-fields, so a state change is a new value.
      expect(action() == action(status: PendingActionStatus.done), isFalse);
    });

    test('exposes its amount as exact money', () {
      expect(action(amountKobo: 1234567).amount, const Money.fromKobo(1234567));
      expect(action(amountKobo: 1234567).amount.format(), '₦12,345.67');
    });

    test('describes itself for logs', () {
      expect(action().toString(), contains('a1'));
      expect(action().toString(), contains('queued'));
    });
  });

  group('json', () {
    test('round-trips through the database', () {
      final original = action(
        status: PendingActionStatus.sending,
        attemptCount: 2,
      );
      final decoded = PendingAction.fromStoredJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.id, 'a1');
      expect(decoded.type, PendingActionType.send);
      expect(decoded.amountKobo, 500000);
      expect(decoded.status, PendingActionStatus.sending);
      expect(decoded.attemptCount, 2);
      expect(decoded.createdAt, original.createdAt);
      expect(decoded.payload['recipient'], '0123456789');
    });

    test('refuses an amount that is not an integer', () {
      // A kobo value that passed through a double must not be coerced.
      final json = action().toJson()..['amountKobo'] = 5000.0;
      expect(() => PendingAction.fromStoredJson(json), throwsFormatException);
    });

    test('refuses a row written by a newer build', () {
      final json = action().toJson()..['schemaVersion'] = 99;
      expect(() => PendingAction.fromStoredJson(json), throwsFormatException);
    });

    test('refuses a row with no schema version', () {
      final json = action().toJson()..remove('schemaVersion');
      expect(() => PendingAction.fromStoredJson(json), throwsFormatException);
    });

    test('refuses unknown enum values rather than guessing', () {
      expect(
        () =>
            PendingAction.fromStoredJson(action().toJson()..['status'] = 'odd'),
        throwsFormatException,
      );
      expect(
        () => PendingAction.fromStoredJson(
          action().toJson()..['type'] = 'teleport',
        ),
        throwsFormatException,
      );
    });

    test('refuses malformed field types', () {
      expect(
        () => PendingAction.fromStoredJson(action().toJson()..['id'] = 7),
        throwsFormatException,
      );
      expect(
        () =>
            PendingAction.fromStoredJson(action().toJson()..['createdAt'] = 12),
        throwsFormatException,
      );
    });
  });
}
