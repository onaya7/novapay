import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/section_header.dart';

import '../../helpers/helpers.dart';

// A 1x1 transparent PNG, so the image variant does not depend on a real
// asset bundle being registered for this test.
final _pixel = MemoryImage(
  Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
    0x00,
    0x00,
    0x00,
    0x0d,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1f,
    0x15,
    0xc4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0a,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9c,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0d,
    0x0a,
    0x2d,
    0xb4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4e,
    0x44,
    0xae,
    0x42,
    0x60,
    0x82,
  ]),
);

void main() {
  group('SectionHeader', () {
    testWidgets('a plain header is just its title', (tester) async {
      await tester.pumpApp(const SectionHeader(title: 'Activity'));

      expect(find.text('Activity'), findsOneWidget);
      expect(find.byType(CustomButton), findsNothing);
    });

    testWidgets('an action sits on the right and fires', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        SectionHeader(
          title: 'Activity',
          actionLabel: 'See all',
          onAction: () => taps++,
        ),
      );

      expect(find.text('See all'), findsOneWidget);
      await tester.tap(find.text('See all'));
      expect(taps, 1);
    });

    testWidgets('an action with no callback renders dead', (tester) async {
      await tester.pumpApp(
        const SectionHeader(title: 'Activity', actionLabel: 'See all'),
      );

      expect(
        tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
        isNull,
      );
    });
  });

  group('AppAvatar', () {
    testWidgets('carries an icon on the brand tint', (tester) async {
      await tester.pumpApp(const AppAvatar(icon: Icons.wallet));

      expect(find.byIcon(Icons.wallet), findsOneWidget);
      final box = tester.widget<Container>(find.byType(Container));
      expect(
        (box.decoration! as BoxDecoration).color,
        AppThemeColors.light.brandSubtle,
      );
    });

    testWidgets('sizes to what it is given', (tester) async {
      await tester.pumpApp(
        const Center(child: AppAvatar(icon: Icons.wallet, size: 64)),
      );

      expect(tester.getSize(find.byType(Container)), const Size(64, 64));
    });

    testWidgets('a photo replaces the icon, not just tints it', (tester) async {
      await tester.pumpApp(AppAvatar(icon: Icons.wallet, image: _pixel));

      expect(find.byIcon(Icons.wallet), findsNothing);
      final box = tester.widget<Container>(find.byType(Container));
      expect((box.decoration! as BoxDecoration).image?.image, _pixel);
    });
  });
}
