import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/constants/app_color.dart';

import '../../helpers/helpers.dart';

ButtonStyle _styleOf(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton)).style!;

Color? _resolve(WidgetStateProperty<Color?>? property) =>
    property?.resolve(const <WidgetState>{});

void main() {
  group('CustomButton', () {
    testWidgets('names the action and fires it', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        CustomButton(label: 'Send ₦5,000.00', onPressed: () => taps++),
      );

      expect(find.text('Send ₦5,000.00'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 1);
    });

    testWidgets('a null callback leaves the button dead', (tester) async {
      await tester.pumpApp(const CustomButton(label: 'Send', onPressed: null));

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('disabled is a neutral fill, not faded brand', (tester) async {
      await tester.pumpApp(const CustomButton(label: 'Send', onPressed: null));

      final style = _styleOf(tester);
      expect(
        style.backgroundColor?.resolve({WidgetState.disabled}),
        AppThemeColors.light.fill,
      );
      expect(
        style.foregroundColor?.resolve({WidgetState.disabled}),
        AppThemeColors.light.subtext,
      );
    });

    testWidgets('each variant takes its own pair of roles', (tester) async {
      await tester.pumpApp(CustomButton(label: 'Primary', onPressed: () {}));
      expect(_resolve(_styleOf(tester).backgroundColor), AppColor.brand);
      expect(_resolve(_styleOf(tester).foregroundColor), AppColor.onBrand);

      await tester.pumpApp(
        CustomButton(
          label: 'Secondary',
          onPressed: () {},
          variant: ButtonVariant.secondary,
        ),
      );
      expect(
        _resolve(_styleOf(tester).backgroundColor),
        AppThemeColors.light.fill,
      );
      expect(
        _resolve(_styleOf(tester).foregroundColor),
        AppThemeColors.light.textHeading,
      );

      await tester.pumpApp(
        CustomButton(
          label: 'Plain',
          onPressed: () {},
          variant: ButtonVariant.plain,
        ),
      );
      expect(_resolve(_styleOf(tester).backgroundColor), Colors.transparent);
      expect(
        _resolve(_styleOf(tester).foregroundColor),
        AppThemeColors.light.primaryStrong,
      );
    });

    testWidgets('loading keeps the label for a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        CustomButton(label: 'Send', onPressed: () {}, isLoading: true),
      );

      expect(find.text('Send'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Send, in progress'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      handle.dispose();
    });

    testWidgets('a leading icon sits beside the label', (tester) async {
      await tester.pumpApp(
        CustomButton(
          label: 'Fund Wallet',
          onPressed: () {},
          leading: const Icon(Icons.add),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Fund Wallet'), findsOneWidget);
    });

    testWidgets('expand false stops it filling the row', (tester) async {
      await tester.pumpApp(
        Center(
          child: CustomButton(
            label: 'Try again',
            onPressed: () {},
            expand: false,
          ),
        ),
      );

      final width = tester.getSize(find.byType(FilledButton)).width;
      expect(width, lessThan(800));
    });

    testWidgets('the button grows past 52 rather than clipping text', (
      tester,
    ) async {
      await tester.pumpApp(CustomButton(label: 'Send', onPressed: () {}));

      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(52),
      );
    });
  });
}
