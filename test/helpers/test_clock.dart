import 'package:novapay/core/time/clock.dart';

/// A clock the test moves by hand, so a backoff window can be crossed without
/// waiting for it.
class TestClock implements Clock {
  TestClock([DateTime? start]) : _now = start ?? DateTime(2026, 9, 16, 12);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);
}
