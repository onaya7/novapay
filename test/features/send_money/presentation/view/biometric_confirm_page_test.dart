import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_draft.dart';
import 'package:novapay/features/send_money/presentation/cubit/send_money_cubit.dart';
import 'package:novapay/features/send_money/presentation/view/biometric_confirm_page.dart';

import '../../../../helpers/helpers.dart';

class _MockSendMoneyCubit extends MockCubit<SendMoneyState>
    implements SendMoneyCubit;

void main() {
  late _MockSendMoneyCubit cubit;

  const draft = TransferDraft(
    step: SendStep.confirm,
    recipient: '0123456789',
    amount: Money.fromKobo(6000000),
  );

  Future<void> pump(WidgetTester tester) => tester.pumpApp(
    BlocProvider<SendMoneyCubit>.value(
      value: cubit,
      child: const BiometricConfirmPage(),
    ),
  );

  setUp(() {
    cubit = _MockSendMoneyCubit();
    whenListen(
      cubit,
      const Stream<SendMoneyState>.empty(),
      initialState: const SendMoneyState.editing(draft),
    );
    when(cubit.submit).thenAnswer((_) async {});
  });

  testWidgets('names the exact amount being confirmed', (tester) async {
    await pump(tester);

    expect(find.textContaining('₦60,000.00'), findsOneWidget);
  });

  testWidgets('confirming submits after the simulated prompt, then leaves', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(CustomButton));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    verify(cubit.submit).called(1);
    expect(find.byType(BiometricConfirmPage), findsNothing);
  });
}
