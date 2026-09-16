import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/money/money.dart';

part 'pending_action.freezed.dart';
part 'pending_action.g.dart';

enum PendingActionType {
  send,
  contribute,

  /// Money arriving rather than leaving, so it never reduces what may be
  /// spent while it is queued.
  fund;

  bool get isOutgoing => this != fund;
}

/// The terminal states are split by what is **known**, not by how many
/// attempts were spent. A transport failure is not evidence the server did
/// nothing, so it can never produce a state the app will retry on its own.
enum PendingActionStatus {
  queued,
  sending,

  /// The server acknowledged it.
  done,

  /// The server refused it definitively. Provably not processed, so the hold
  /// is released and the customer may try again with a fresh key.
  rejected,

  /// At least one attempt was transmitted without a readable answer. It may
  /// have moved money. Held, and never auto-resent.
  unresolved;

  /// Still owes the customer an outcome, so the UI shows it as Pending.
  bool get isPending => this == queued || this == sending;

  /// Nothing more will happen without a decision.
  bool get isTerminal => this == done || this == rejected || this == unresolved;

  /// Money the customer cannot spend: still owed, or possibly already gone.
  bool get holdsFunds => isPending || this == unresolved;
}

/// Bumped when the stored shape changes, so an older build refuses a row it
/// cannot read instead of misreading it.
const int kPendingActionSchemaVersion = 3;

/// How many ambiguous attempts are made before the customer has to decide.
const int kPendingActionMaxAttempts = 5;

/// First backoff step; each further attempt doubles it.
const Duration kPendingActionBaseBackoff = Duration(seconds: 2);

/// Ceiling, so a long outage does not push the next try days out.
const Duration kPendingActionMaxBackoff = Duration(minutes: 30);

/// One row in the local queue: a money action the customer asked for, saved to
/// the database before any network call so it survives being offline or killed.
@freezed
abstract class PendingAction with _$PendingAction {
  const factory PendingAction({
    /// A UUID, generated once and sent as the idempotency key. The server
    /// collapses a replay with the same key instead of moving money twice.
    required String id,
    required PendingActionType type,
    // koboFromJson throws rather than coercing a double into money.
    @JsonKey(fromJson: koboFromJson) required int amountKobo,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
    @Default(PendingActionStatus.queued) PendingActionStatus status,
    @Default(0) int attemptCount,

    /// Fresh per attempt, for tracing. Never used for deduplication.
    String? attemptId,

    /// One-way: set by any attempt that was transmitted without a readable
    /// answer, and never cleared.
    @Default(false) bool sawAmbiguousAttempt,

    /// Persisted, because an in-memory backoff resets on restart and produces
    /// a thundering herd on the first cold start after a crash loop.
    DateTime? nextAttemptAt,

    /// Why it was refused, in words the customer can act on.
    String? failureMessage,
    @Default(kPendingActionSchemaVersion) int schemaVersion,
  }) = _PendingAction;

  const PendingAction._();

  factory PendingAction.fromJson(Map<String, dynamic> json) =>
      _$PendingActionFromJson(json);

  /// Decodes a row read back from the database, checking the schema first.
  ///
  /// Throws [FormatException] on a row this build cannot read, so the queue
  /// can drop one bad entry instead of being stranded by it.
  factory PendingAction.fromStoredJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int) {
      throw const FormatException('pending action has no schemaVersion');
    }
    if (version > kPendingActionSchemaVersion) {
      throw FormatException('schemaVersion $version is from a newer build');
    }
    try {
      return PendingAction.fromJson(json);
    } on Object catch (error) {
      // One failure mode for an unreadable row, whatever the generated
      // decoder threw, so callers only have to handle FormatException.
      throw FormatException('unreadable pending action row: $error');
    }
  }

  Money get amount => Money.fromKobo(amountKobo);

  /// Ready to try now: pending, and past any backoff window.
  bool isRunnableAt(DateTime now) {
    if (!status.isPending) return false;
    final due = nextAttemptAt;
    return due == null || !now.isBefore(due);
  }

  /// A send interrupted by a crash was transmitted, so it may have been
  /// processed. Safe to resend only because the id is the idempotency key.
  PendingAction recovered() => status == PendingActionStatus.sending
      ? copyWith(status: PendingActionStatus.queued, sawAmbiguousAttempt: true)
      : this;

  PendingAction sending(String attemptId) => copyWith(
    status: PendingActionStatus.sending,
    attemptId: attemptId,
    attemptCount: attemptCount + 1,
  );

  PendingAction succeeded() =>
      copyWith(status: PendingActionStatus.done, nextAttemptAt: null);

  /// The server answered and said no. Nothing moved, so the hold is released.
  PendingAction refused(String message) => copyWith(
    status: PendingActionStatus.rejected,
    failureMessage: message,
    nextAttemptAt: null,
  );

  /// The request was transmitted but no answer came back. Retried with the
  /// same key until the budget runs out, then handed to the customer.
  PendingAction ambiguousAttempt(DateTime now) {
    final exhausted = attemptCount >= kPendingActionMaxAttempts;
    return copyWith(
      status: exhausted
          ? PendingActionStatus.unresolved
          : PendingActionStatus.queued,
      sawAmbiguousAttempt: true,
      nextAttemptAt: exhausted ? null : now.add(_backoff),
    );
  }

  /// Exponential, and jittered off the id so a whole cell tower reconnecting
  /// at once does not retry in lockstep.
  Duration get _backoff {
    final step =
        kPendingActionBaseBackoff * (1 << (attemptCount - 1).clamp(0, 16));
    final capped = step > kPendingActionMaxBackoff
        ? kPendingActionMaxBackoff
        : step;
    final jitter = capped.inMilliseconds ~/ 4;
    return capped + Duration(milliseconds: id.hashCode.abs() % (jitter + 1));
  }
}
