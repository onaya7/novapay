import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/constants/app_size.dart';

void main() {
  group('AppSize', () {
    test('spacing stays on the 4pt rhythm', () {
      const scale = [
        AppSize.xs,
        AppSize.sm,
        AppSize.smd,
        AppSize.md,
        AppSize.mdl,
        AppSize.lg,
        AppSize.xl,
        AppSize.xxl,
        AppSize.xxxl,
        AppSize.huge,
      ];

      expect(scale.every((step) => step % 4 == 0), isTrue);
    });

    test('icons snap to the three-step ramp', () {
      expect([AppSize.iconSm, AppSize.iconMd, AppSize.iconLg], [16, 20, 24]);
    });

    test('a touch target is never below 44', () {
      expect(AppSize.touchTarget, greaterThanOrEqualTo(44));
    });

    test('gap helpers size only the axis they name', () {
      expect(AppSize.h(AppSize.md).height, AppSize.md);
      expect(AppSize.h(AppSize.md).width, isNull);
      expect(AppSize.w(AppSize.sm).width, AppSize.sm);
      expect(AppSize.w(AppSize.sm).height, isNull);
    });
  });
}
