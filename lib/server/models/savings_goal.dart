import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/money/money.dart';

part 'savings_goal.freezed.dart';
part 'savings_goal.g.dart';

@freezed
abstract class SavingsGoal with _$SavingsGoal {
  const factory SavingsGoal({
    required String id,
    required String name,
    // koboFromJson throws rather than coercing a double into money.
    @JsonKey(fromJson: koboFromJson) required int targetKobo,
    required DateTime targetDate,
    @JsonKey(fromJson: koboFromJson) @Default(0) int savedKobo,
  }) = _SavingsGoal;

  const SavingsGoal._();

  factory SavingsGoal.fromJson(Map<String, dynamic> json) =>
      _$SavingsGoalFromJson(json);

  Money get target => Money.fromKobo(targetKobo);

  Money get saved => Money.fromKobo(savedKobo);

  Money get remaining =>
      Money.fromKobo((targetKobo - savedKobo).clamp(0, targetKobo));

  /// Whole percent, computed in integers and printed beside the bar.
  int get percentComplete => progressPercent(saved: saved, target: target);

  /// The 0..1 value a progress bar takes. One-way: never read back as text.
  double get progressFraction =>
      progressBasisPoints(saved: saved, target: target) / 10000;

  bool get isComplete => savedKobo >= targetKobo;
}
