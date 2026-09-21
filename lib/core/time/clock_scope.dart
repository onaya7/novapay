import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/time/clock.dart';

/// Lets a golden pin "now"; without a scope the widget reads the system clock.
class ClockScope extends InheritedWidget {
  const new({required this.clock, required super.child, super.key});

  final Clock clock;

  static Clock of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ClockScope>()?.clock ??
      const SystemClock();

  @override
  bool updateShouldNotify(ClockScope oldWidget) => clock != oldWidget.clock;
}
