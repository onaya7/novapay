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
      expect(PendingActionStatus.rejected.isPending, isFalse);
      expect(PendingActionStatus.unresolved.isPending, isFalse);
    });

    test('an outcome is terminal; being in flight is not', () {
      expect(PendingActionStatus.done.isTerminal, isTrue);
      expect(PendingActionStatus.rejected.isTerminal, isTrue);
      expect(PendingActionStatus.unresolved.isTerminal, isTrue);
      expect(PendingActionStatus.queued.isTerminal, isFalse);
      expect(PendingActionStatus.sending.isTerminal, isFalse);
    });

    test('an unknown outcome still holds the money; a refusal releases it', () {
      // Releasing the hold on an unknown outcome is a double-spend through the
      // UI: the customer sees it come back, spends it, then the send lands.
      expect(PendingActionStatus.unresolved.holdsFunds, isTrue);
      expect(PendingActionStatus.queued.holdsFunds, isTrue);
      expect(PendingActionStatus.sending.holdsFunds, isTrue);
      expect(PendingActionStatus.rejected.holdsFunds, isFalse);
      expect(PendingActionStatus.done.holdsFunds, isFalse);
    });
  });

  group('runnability', () {
    final now = DateTime.utc(2026, 9, 16, 12);

    test('a fresh action runs at once', () {
      expect(action().isRunnableAt(now), isTrue);
    });

    test('a terminal action never runs again', () {
      expect(
        action(status: PendingActionStatus.rejected).isRunnableAt(now),
        isFalse,
      );
      expect(
        action(status: PendingActionStatus.unresolved).isRunnableAt(now),
        isFalse,
      );
      expect(action(status: PendingActionStatus.done).isRunnableAt(now), false);
    });

    test('a backoff window holds it until the deadline passes', () {
      final waiting = action().copyWith(
        nextAttemptAt: now.add(const Duration(minutes: 5)),
      );

      expect(waiting.isRunnableAt(now), isFalse);
      expect(
        waiting.isRunnableAt(now.add(const Duration(minutes: 4))),
        isFalse,
      );
      expect(waiting.isRunnableAt(now.add(const Duration(minutes: 5))), isTrue);
      expect(waiting.isRunnableAt(now.add(const Duration(minutes: 6))), isTrue);
    });
  });

  group('transitions', () {
    final now = DateTime.utc(2026, 9, 16, 12);

    test('starting an attempt spends one and records a trace id', () {
      final sending = action().sending('attempt-1');
      expect(sending.status, PendingActionStatus.sending);
      expect(sending.attemptCount, 1);
      expect(sending.attemptId, 'attempt-1');
    });

    test('the trace id changes per attempt while the key does not', () {
      final first = action().sending('attempt-1');
      final second = first.ambiguousAttempt(now).sending('attempt-2');

      expect(first.id, second.id);
      expect(first.attemptId, isNot(second.attemptId));
    });

    test('success finishes it and clears any backoff', () {
      final done = action(
        status: PendingActionStatus.sending,
        attemptCount: 1,
      ).copyWith(nextAttemptAt: now).succeeded();

      expect(done.status, PendingActionStatus.done);
      expect(done.nextAttemptAt, isNull);
    });

    test('a refusal is terminal and keeps the reason', () {
      final refused = action(status: PendingActionStatus.sending)
          .refused('Not enough in your wallet');

      expect(refused.status, PendingActionStatus.rejected);
      expect(refused.failureMessage, 'Not enough in your wallet');
      expect(refused.sawAmbiguousAttempt, isFalse);
    });

    test('an ambiguous attempt requeues behind a backoff', () {
      final again = action(attemptCount: 1).ambiguousAttempt(now);

      expect(again.status, PendingActionStatus.queued);
      expect(again.sawAmbiguousAttempt, isTrue);
      expect(again.nextAttemptAt, isNotNull);
      expect(again.nextAttemptAt!.isAfter(now), isTrue);
    });

    test('the backoff grows with each attempt', () {
      Duration waitAfter(int attempts) =>
          action(attemptCount: attempts)
              .ambiguousAttempt(now)
              .nextAttemptAt!
              .difference(now);

      expect(waitAfter(2) > waitAfter(1), isTrue);
      expect(waitAfter(3) > waitAfter(2), isTrue);
    });

    test('the backoff is capped, so a long outage stays reachable', () {
      final wait = action(attemptCount: 4)
          .ambiguousAttempt(now)
          .nextAttemptAt!
          .difference(now);

      // Capped value plus at most a quarter of it as jitter.
      expect(wait <= kPendingActionMaxBackoff * 1.25, isTrue);
    });

    test('an exhausted budget hands it to the customer, not to a retry', () {
      final exhausted = action(attemptCount: kPendingActionMaxAttempts)
          .ambiguousAttempt(now);

      expect(exhausted.status, PendingActionStatus.unresolved);
      expect(exhausted.sawAmbiguousAttempt, isTrue);
      // No deadline: nothing will pick it up again on its own.
      expect(exhausted.nextAttemptAt, isNull);
    });

    test('a send interrupted by a crash goes back, and is marked unknown', () {
      // Safe to resend, because the id is the idempotency key. It was
      // transmitted, so the outcome is unknown rather than known-not-sent.
      final stuck = action(status: PendingActionStatus.sending);
      expect(stuck.recovered().status, PendingActionStatus.queued);
      expect(stuck.recovered().sawAmbiguousAttempt, isTrue);
    });

    test('the ambiguous flag is one-way', () {
      final flagged = action(status: PendingActionStatus.sending)
          .recovered()
          .sending('attempt-2')
          .succeeded();

      expect(flagged.sawAmbiguousAttempt, isTrue);
    });

    test('recovery leaves every other state alone', () {
      for (final status in [
        PendingActionStatus.queued,
        PendingActionStatus.done,
        PendingActionStatus.rejected,
        PendingActionStatus.unresolved,
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
      a = a.sending('attempt-1');
      a = a.ambiguousAttempt(now);
      a = a.sending('attempt-2');
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
