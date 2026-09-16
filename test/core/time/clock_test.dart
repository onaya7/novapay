import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/time/clock.dart';

void main() {
  group('SystemClock', () {
    test('reads wall time', () {
      // A const instance is canonicalized, so the constructor never runs.
      // ignore: prefer_const_constructors
      final clock = SystemClock();
      final before = DateTime.now();

      final read = clock.now();

      expect(read.isBefore(before), isFalse);
      expect(read.difference(before).inSeconds.abs(), lessThan(5));
    });

    test('moves forward on its own, unlike a test clock', () async {
      const clock = SystemClock();
      final first = clock.now();

      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(clock.now().isAfter(first), isTrue);
    });
  });
}
