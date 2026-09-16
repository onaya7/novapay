import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/money/money.dart';

part 'pending_action.freezed.dart';
part 'pending_action.g.dart';

enum PendingActionType { send, contribute }

enum PendingActionStatus {
  queued,
  sending,
  done,
  failed;

  /// Still owes the user an outcome, so the UI shows it as Pending.
  bool get isPending => this == queued || this == sending;
}

/// Bumped when the stored shape changes, so an older build refuses a row it
/// cannot read instead of misreading it.
const int kPendingActionSchemaVersion = 1;

/// How many times a single action is attempted before the queue gives up.
const int kPendingActionMaxAttempts = 5;

/// One row in the local queue: a money action the user asked for, saved to the
/// database before any network call so it survives being offline or killed.
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

  /// A send interrupted by a crash is safe to resend, because the id is the
  /// idempotency key.
  PendingAction recovered() => status == PendingActionStatus.sending
      ? copyWith(status: PendingActionStatus.queued)
      : this;

  PendingAction sending() => copyWith(status: PendingActionStatus.sending);

  PendingAction succeeded() => copyWith(
    status: PendingActionStatus.done,
    attemptCount: attemptCount + 1,
  );

  /// Requeues until the budget runs out, then stops so it cannot spin.
  PendingAction failedAttempt() {
    final attempts = attemptCount + 1;
    return copyWith(
      status: attempts >= kPendingActionMaxAttempts
          ? PendingActionStatus.failed
          : PendingActionStatus.queued,
      attemptCount: attempts,
    );
  }
}
