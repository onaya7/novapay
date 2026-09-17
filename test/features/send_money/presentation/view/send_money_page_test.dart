import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/funding/domain/entities/funding_draft.dart';
import 'package:novapay/features/funding/presentation/cubit/add_money_cubit.dart';
import 'package:novapay/features/funding/presentation/view/add_money_page.dart';
import 'package:novapay/features/send_money/domain/entities/bank.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_draft.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_receipt.dart';
import 'package:novapay/features/send_money/presentation/cubit/send_money_cubit.dart';
import 'package:novapay/features/send_money/presentation/view/biometric_confirm_page.dart';
import 'package:novapay/features/send_money/presentation/view/send_money_page.dart';
import 'package:novapay/features/send_money/presentation/widgets/send_money_widgets.dart';

import '../../../../helpers/helpers.dart';

class _MockSendMoneyCubit extends MockCubit<SendMoneyState>
    implements SendMoneyCubit;

class _MockAddMoneyCubit extends MockCubit<AddMoneyState>
    implements AddMoneyCubit;

const _available = Money.fromKobo(2000000);
const _bank = Bank(code: '058', name: 'Guaranty Trust Bank');
const _otherBank = Bank(code: '044', name: 'Access Bank');

TransferDraft _draft({
  SendStep step = SendStep.recipient,
  Bank? bank = _bank,
  String recipient = '0123456789',
  int amountKobo = 500000,
}) => TransferDraft(
  step: step,
  bank: bank,
  recipient: recipient,
  amount: Money.fromKobo(amountKobo),
  available: _available,
);

void main() {
  late _MockSendMoneyCubit cubit;

  Future<void> pumpView(WidgetTester tester, SendMoneyState state) {
    whenListen(
      cubit,
      const Stream<SendMoneyState>.empty(),
      initialState: state,
    );
    return tester.pumpApp(
      BlocProvider<SendMoneyCubit>.value(
        value: cubit,
        child: const SendMoneyView(),
      ),
    );
  }

  String ctaLabel(WidgetTester tester) =>
      tester.widget<CustomButton>(find.byType(CustomButton).first).label;

  setUpAll(() => registerFallbackValue(_bank));

  setUp(() {
    cubit = _MockSendMoneyCubit();
    when(cubit.start).thenAnswer((_) async {});
    when(cubit.submit).thenAnswer((_) async {});
    when(() => cubit.next()).thenReturn(null);
    when(() => cubit.back()).thenReturn(null);
    when(() => cubit.recipientChanged(any())).thenReturn(null);
    when(() => cubit.bankChanged(any())).thenReturn(null);
    when(() => cubit.amountChanged(any())).thenReturn(null);
  });

  group('step one, recipient', () {
    testWidgets('asks for an account number with a visible label', (
      tester,
    ) async {
      await pumpView(tester, SendMoneyState.editing(_draft(recipient: '')));

      expect(find.text('Send to'), findsOneWidget);
      expect(find.text('Account number'), findsOneWidget);
      expect(find.byType(RecipientStep), findsOneWidget);
    });

    testWidgets('an empty field leaves the CTA dead', (tester) async {
      await pumpView(tester, SendMoneyState.editing(_draft(recipient: '')));

      expect(ctaLabel(tester), 'Continue');
      expect(
        tester.widget<CustomButton>(find.byType(CustomButton).first).onPressed,
        isNull,
      );
    });

    testWidgets('a short number is named as the problem', (tester) async {
      await pumpView(tester, SendMoneyState.editing(_draft(recipient: '123')));

      expect(
        find.text('That is not a ten-digit account number'),
        findsOneWidget,
      );
    });

    testWidgets('a valid number advances on Continue', (tester) async {
      await pumpView(tester, SendMoneyState.editing(_draft()));

      await tester.tap(find.byType(CustomButton));
      verify(() => cubit.next()).called(1);
    });

    testWidgets('typing reaches the cubit', (tester) async {
      await pumpView(tester, SendMoneyState.editing(_draft(recipient: '')));

      await tester.enterText(find.byType(TextField), '0123456789');
      verify(() => cubit.recipientChanged('0123456789')).called(1);
    });

    testWidgets('no bank chosen leaves the CTA dead even with a valid number', (
      tester,
    ) async {
      await pumpView(tester, SendMoneyState.editing(_draft(bank: null)));

      expect(
        tester.widget<CustomButton>(find.byType(CustomButton).first).onPressed,
        isNull,
      );
    });

    testWidgets('the bank selector shows a placeholder until one is chosen', (
      tester,
    ) async {
      await pumpView(tester, SendMoneyState.editing(_draft(bank: null)));

      expect(find.text('Choose a bank'), findsOneWidget);
    });

    testWidgets('a chosen bank replaces the placeholder', (tester) async {
      await pumpView(tester, SendMoneyState.editing(_draft()));

      expect(find.text('Guaranty Trust Bank'), findsOneWidget);
      expect(find.text('Choose a bank'), findsNothing);
    });

    testWidgets('picking a bank from the sheet reaches the cubit', (
      tester,
    ) async {
      await pumpView(
        tester,
        SendMoneyState.editing(_draft(bank: null), banks: const [_bank]),
      );

      await tester.tap(find.text('Choose a bank'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guaranty Trust Bank'));
      await tester.pumpAndSettle();

      verify(() => cubit.bankChanged(_bank)).called(1);
    });

    testWidgets('the sheet filters as the customer searches', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.editing(
          _draft(bank: null),
          banks: const [_bank, _otherBank],
        ),
      );

      await tester.tap(find.text('Choose a bank'));
      await tester.pumpAndSettle();
      expect(find.text('Access Bank'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'guaranty');
      await tester.pumpAndSettle();

      expect(find.text('Guaranty Trust Bank'), findsOneWidget);
      expect(find.text('Access Bank'), findsNothing);
    });

    testWidgets('back from the first step leaves the flow', (tester) async {
      await pumpView(tester, SendMoneyState.editing(_draft(recipient: '')));

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      verifyNever(() => cubit.back());
      expect(find.byType(SendMoneyView), findsNothing);
    });
  });

  group('step two, amount', () {
    testWidgets('shows what is actually spendable', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.editing(_draft(step: SendStep.amount)),
      );

      expect(find.text('How much?'), findsOneWidget);
      expect(find.text('From your wallet'), findsOneWidget);
      expect(find.text('₦20,000.00 available'), findsOneWidget);
    });

    testWidgets('too much swaps the CTA for one that fixes it', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.editing(
          _draft(step: SendStep.amount, amountKobo: 9999999),
        ),
      );

      expect(ctaLabel(tester), 'Fund Wallet');
      expect(find.text('That is more than you have available'), findsOneWidget);
    });

    testWidgets('the blocked CTA is live, not disabled', (tester) async {
      final addMoney = _MockAddMoneyCubit();
      when(addMoney.start).thenAnswer((_) async {});
      whenListen(
        addMoney,
        const Stream<AddMoneyState>.empty(),
        initialState: const AddMoneyState.editing(FundingDraft()),
      );
      sl.registerFactory<AddMoneyCubit>(() => addMoney);
      addTearDown(sl.reset);

      await pumpView(
        tester,
        SendMoneyState.editing(
          _draft(step: SendStep.amount, amountKobo: 9999999),
        ),
      );

      expect(
        tester.widget<CustomButton>(find.byType(CustomButton).first).onPressed,
        isNotNull,
      );
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();
      expect(find.byType(AddMoneyView), findsOneWidget);
    });

    testWidgets('a preset fills the amount without typing', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.editing(_draft(step: SendStep.amount, amountKobo: 0)),
      );

      await tester.tap(find.text('₦5,000.00'));

      verify(() => cubit.amountChanged('5,000.00')).called(1);
    });

    testWidgets('All offers everything that is available', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.editing(_draft(step: SendStep.amount, amountKobo: 0)),
      );

      await tester.tap(find.text('₦20,000.00'));

      verify(() => cubit.amountChanged('20,000.00')).called(1);
    });

    testWidgets('back returns to the recipient step', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.editing(_draft(step: SendStep.amount)),
      );

      await tester.tap(find.byTooltip('Back'));
      verify(() => cubit.back()).called(1);
    });

    testWidgets('a system back also steps back rather than leaving', (
      tester,
    ) async {
      await pumpView(
        tester,
        SendMoneyState.editing(_draft(step: SendStep.amount)),
      );

      final scope = tester.widget<PopScope<Object?>>(
        find.byWidgetPredicate((widget) => widget is PopScope<Object?>),
      );
      expect(scope.canPop, isFalse);
      scope.onPopInvokedWithResult?.call(false, null);

      verify(() => cubit.back()).called(1);
    });
  });

  group('step three, confirm', () {
    testWidgets('the button names the exact amount', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.editing(_draft(step: SendStep.confirm)),
      );

      expect(find.text('Confirm'), findsOneWidget);
      expect(ctaLabel(tester), 'Send ₦5,000.00');
    });

    testWidgets('it shows the masked account and what is left', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.editing(_draft(step: SendStep.confirm)),
      );

      expect(find.text('•••••• 6789'), findsOneWidget);
      expect(find.text('₦15,000.00'), findsOneWidget);
    });

    testWidgets('submitting shows progress on the button', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.submitting(_draft(step: SendStep.confirm)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('the button queues the transfer', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.editing(_draft(step: SendStep.confirm)),
      );

      await tester.tap(find.byType(CustomButton).first);
      verify(cubit.submit).called(1);
    });

    testWidgets(
      'above the biometric threshold, Send opens the biometric prompt first',
      (tester) async {
        await pumpView(
          tester,
          const SendMoneyState.editing(
            TransferDraft(
              step: SendStep.confirm,
              bank: _bank,
              recipient: '0123456789',
              amount: Money.fromKobo(6000000),
              available: Money.fromKobo(6000000),
            ),
          ),
        );

        await tester.tap(find.byType(CustomButton).first);
        await tester.pump();

        expect(find.byType(BiometricConfirmPage), findsOneWidget);
        verifyNever(cubit.submit);
      },
    );

    testWidgets('Cancel abandons the transfer without sending', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.editing(_draft(step: SendStep.confirm)),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(cubit.submit);
      expect(find.byType(SendMoneyView), findsNothing);
    });

    testWidgets('Cancel is dead while the transfer is in flight', (
      tester,
    ) async {
      await pumpView(
        tester,
        SendMoneyState.submitting(_draft(step: SendStep.confirm)),
      );

      expect(
        tester.widget<CustomButton>(find.byType(CustomButton).last).onPressed,
        isNull,
      );
    });
  });

  group('the receipt', () {
    testWidgets('a settled transfer says Sent', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.done(
          _draft(step: SendStep.confirm),
          const TransferReceipt(
            reference: 'r1',
            bankName: 'Guaranty Trust Bank',
            recipient: '0123456789',
            amount: Money.fromKobo(500000),
            settled: true,
          ),
        ),
      );

      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Money sent'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets('a queued transfer never claims it was sent', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.done(
          _draft(step: SendStep.confirm),
          const TransferReceipt(
            reference: 'r1',
            bankName: 'Guaranty Trust Bank',
            recipient: '0123456789',
            amount: Money.fromKobo(500000),
            settled: false,
          ),
        ),
      );

      expect(find.text('Queued'), findsNWidgets(2));
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.textContaining('closing the app will not lose it'), findsOne);
    });

    testWidgets('Back to wallet leaves the flow', (tester) async {
      await pumpView(
        tester,
        SendMoneyState.done(
          _draft(step: SendStep.confirm),
          const TransferReceipt(
            reference: 'r1',
            bankName: 'Guaranty Trust Bank',
            recipient: '0123456789',
            amount: Money.fromKobo(500000),
            settled: true,
          ),
        ),
      );

      await tester.tap(find.text('Back to wallet'));
      await tester.pumpAndSettle();

      expect(find.byType(SendMoneyView), findsNothing);
    });
  });

  group('SendMoneyPage', () {
    setUp(() {
      sl.registerFactory<SendMoneyCubit>(() => cubit);
      whenListen(
        cubit,
        const Stream<SendMoneyState>.empty(),
        initialState: const SendMoneyState.editing(TransferDraft()),
      );
    });

    tearDown(sl.reset);

    testWidgets('resolves its cubit and starts it', (tester) async {
      await tester.pumpApp(const SendMoneyPage());

      expect(find.byType(SendMoneyView), findsOneWidget);
      verify(cubit.start).called(1);
    });
  });
}
