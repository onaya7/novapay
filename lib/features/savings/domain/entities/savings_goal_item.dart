import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/extensions/date_time_extension.dart';
import 'package:novapay/core/money/money.dart';

part 'savings_goal_item.freezed.dart';

/// A goal as the app shows it: what the server has settled, plus what is still
/// sitting in the local queue on its way there.
@freezed
abstract class SavingsGoalItem with _$SavingsGoalItem {
  const factory SavingsGoalItem({
    required String id,
    required String name,
    required int targetKobo,
    required int savedKobo,
    required DateTime targetDate,
    @Default(0) int pendingKobo,
  }) = _SavingsGoalItem;

  const SavingsGoalItem._();

  Money get target => Money.fromKobo(targetKobo);

  /// Settled only. The server's number, never computed on the client.
  Money get saved => Money.fromKobo(savedKobo);

  Money get pending => Money.fromKobo(pendingKobo);

  /// What it will be worth once the queue drains.
  Money get projected => Money.fromKobo(savedKobo + pendingKobo);

  Money get remaining => Money.fromKobo(
    (targetKobo - savedKobo - pendingKobo).clamp(0, targetKobo),
  );

  bool get hasPending => pendingKobo > 0;

  /// Whole percent, computed in integers and printed beside the bar.
  int get percentComplete => progressPercent(saved: projected, target: target);

  /// The 0..1 value the bar takes. One-way: never read back as text.
  double get progressFraction =>
      progressBasisPoints(saved: projected, target: target) / 10000;

  /// The settled share, drawn under the projected one.
  double get settledFraction =>
      progressBasisPoints(saved: saved, target: target) / 10000;

  bool get isComplete => savedKobo + pendingKobo >= targetKobo;

  int get daysLeft => targetDate.daysFromNow;

  bool get isOverdue => !isComplete && daysLeft < 0;

  /// What the card says under the name, so the view holds no date logic.
  String get dueLabel {
    if (isComplete) return 'Goal reached';
    final days = daysLeft;
    if (days < 0) return 'Target date passed';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }
}
