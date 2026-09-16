import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/money/money.dart';

part 'activity_item.freezed.dart';

enum ActivityStatus {
  settled,
  pending,

  /// The server said no. Nothing moved, and it can be tried again.
  rejected,

  /// Transmitted without a readable answer. It may have moved money, so the
  /// customer is asked to check rather than told it failed.
  unresolved,
}

/// One row of the activity list: a settled transaction from the server, or a
/// money action still sitting in the local queue.
@freezed
abstract class ActivityItem with _$ActivityItem {
  const factory ActivityItem({
    required String id,
    required String title,
    required int amountKobo,
    required DateTime occurredAt,
    required ActivityStatus status,
    String? failureMessage,
  }) = _ActivityItem;

  const ActivityItem._();

  Money get amount => Money.fromKobo(amountKobo);

  bool get isDebit => amountKobo < 0;

  /// What the customer should do, when there is something to do.
  String? get note => switch (status) {
    ActivityStatus.settled || ActivityStatus.pending => null,
    ActivityStatus.rejected => failureMessage ?? 'This one did not go through.',
    ActivityStatus.unresolved =>
      "We couldn't confirm this transfer. Check your history before trying "
          'again.',
  };
}
