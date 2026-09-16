import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/status_chip.dart';
import 'package:novapay/core/constants/app_color.dart';

import '../../helpers/helpers.dart';

Color _dotColor(WidgetTester tester) {
  final dot = tester.widgetList<Container>(find.byType(Container)).last;
  return (dot.decoration! as BoxDecoration).color!;
}

void main() {
  group('StatusChip', () {
    testWidgets('carries the state in the word, not only the color', (
      tester,
    ) async {
      await tester.pumpApp(
        const StatusChip(label: 'Pending', tone: ChipTone.pending),
      );

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('the pill stays neutral so the label keeps contrast', (
      tester,
    ) async {
      await tester.pumpApp(
        const StatusChip(label: 'Pending', tone: ChipTone.pending),
      );

      final pill = tester.widgetList<Container>(find.byType(Container)).first;
      expect(
        (pill.decoration! as BoxDecoration).color,
        AppThemeColors.light.fill,
      );
    });

    testWidgets('each tone picks its own dot', (tester) async {
      await tester.pumpApp(
        const StatusChip(label: 'Pending', tone: ChipTone.pending),
      );
      expect(_dotColor(tester), AppThemeColors.light.warning);

      await tester.pumpApp(
        const StatusChip(label: 'Sent', tone: ChipTone.success),
      );
      expect(_dotColor(tester), AppColor.success);

      await tester.pumpApp(
        const StatusChip(label: 'Rejected', tone: ChipTone.danger),
      );
      expect(_dotColor(tester), AppColor.danger);
    });

    testWidgets('the pending dot brightens in dark mode', (tester) async {
      await tester.pumpApp(
        const StatusChip(label: 'Pending', tone: ChipTone.pending),
        theme: AppTheme.dark,
      );

      expect(_dotColor(tester), AppColor.warningDark);
    });
  });
}
