import 'package:injectable/injectable.dart';

/// Injected so backoff can be tested without waiting for it.
abstract class Clock {
  DateTime now();
}

@LazySingleton(as: Clock)
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
