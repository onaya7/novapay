import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/money/money.dart';

part 'activity_item.freezed.dart';

enum ActivityStatus { settled, pending, failed }

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
  }) = _ActivityItem;

  const ActivityItem._();

  Money get amount => Money.fromKobo(amountKobo);

  bool get isDebit => amountKobo < 0;

  /// Settled rows are the rule, so only the exceptions are annotated.
  bool get needsChip => status != ActivityStatus.settled;
}
