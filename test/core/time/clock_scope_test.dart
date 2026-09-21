import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/time/clock.dart';
import 'package:novapay/core/time/clock_scope.dart';

import '../../helpers/test_clock.dart';

void main() {
  group('ClockScope', () {
    testWidgets('falls back to the system clock when nothing scopes it', (
      tester,
    ) async {
      late Clock resolved;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            resolved = ClockScope.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(resolved, isA<SystemClock>());
    });

    testWidgets('hands down the clock it was given', (tester) async {
      final clock = TestClock(DateTime(2026, 9, 17, 9));
      late DateTime seen;
      await tester.pumpWidget(
        ClockScope(
          clock: clock,
          child: Builder(
            builder: (context) {
              seen = ClockScope.of(context).now();
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen, DateTime(2026, 9, 17, 9));
    });

    test('notifies only when the clock itself changed', () {
      const child = SizedBox.shrink();
      final clock = TestClock();
      final scope = ClockScope(clock: clock, child: child);

      expect(
        scope.updateShouldNotify(ClockScope(clock: clock, child: child)),
        isFalse,
      );
      expect(
        scope.updateShouldNotify(ClockScope(clock: TestClock(), child: child)),
        isTrue,
      );
    });
  });
}
