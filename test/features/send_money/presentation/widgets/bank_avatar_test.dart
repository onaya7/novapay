import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/features/send_money/domain/entities/bank.dart';
import 'package:novapay/features/send_money/presentation/widgets/bank_avatar.dart';
import 'package:novapay/gen/assets.gen.dart';

import '../../../../helpers/helpers.dart';

void main() {
  testWidgets('a bank with no bundled logo falls back to initials', (
    tester,
  ) async {
    await tester.pumpApp(
      const BankAvatar(
        bank: Bank(code: '999', name: 'Providus Bank'),
      ),
    );

    expect(find.text('PB'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a bank with a bundled logo renders it, not the initials', (
    tester,
  ) async {
    await tester.pumpApp(
      BankAvatar(
        bank: Bank(
          code: '058',
          name: 'Guaranty Trust Bank',
          logoAsset: Assets.images.banks.gtbank.path,
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('GT'), findsNothing);
  });
}
