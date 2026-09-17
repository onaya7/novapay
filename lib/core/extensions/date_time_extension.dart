import 'package:intl/intl.dart';

final DateFormat _dayMonth = DateFormat('d MMM');
final DateFormat _dayMonthYear = DateFormat('d MMM y');
final DateFormat _clock = DateFormat('HH:mm');

extension DateTimeX on DateTime {
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool get isToday => isSameDayAs(DateTime.now());

  bool get isYesterday =>
      isSameDayAs(DateTime.now().subtract(const Duration(days: 1)));

  /// What a transaction row shows: [today]/[yesterday], `14 Sep`, or the year
  /// as well once it is no longer this year. Localized words are supplied by
  /// the caller, since a plain `DateTime` extension has no `BuildContext`.
  String dayLabel({required String today, required String yesterday}) {
    if (isToday) return today;
    if (isYesterday) return yesterday;
    if (year == DateTime.now().year) return _dayMonth.format(this);
    return _dayMonthYear.format(this);
  }

  String get timeLabel => _clock.format(this);

  /// Morning until noon, afternoon until 17:00, evening after. Localized
  /// words are supplied by the caller, for the same reason as [dayLabel].
  String greeting({
    required String morning,
    required String afternoon,
    required String evening,
  }) {
    if (hour < 12) return morning;
    if (hour < 17) return afternoon;
    return evening;
  }

  /// Whole days from now, negative once the date is past.
  int get daysFromNow {
    final now = DateTime.now();
    return DateTime(
      year,
      month,
      day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}
