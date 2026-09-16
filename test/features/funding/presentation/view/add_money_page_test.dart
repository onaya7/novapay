import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/funding/domain/entities/funding_draft.dart';
import 'package:novapay/features/funding/presentation/cubit/add_money_cubit.dart';
import 'package:novapay/features/funding/presentation/view/add_money_page.dart';

import '../../../../helpers/helpers.dart';

class _MockAddMoneyCubit extends MockCubit<AddMoneyState>
    implements AddMoneyCubit;

void main() {
  late _MockAddMoneyCubit cubit;

  Future<void> pump(WidgetTester tester, AddMoneyState state) {
    whenListen(cubit, const Stream<AddMoneyState>.empty(), initialState: state);
    return tester.pumpApp(
      BlocProvider<AddMoneyCubit>.value(
        value: cubit,
        child: const AddMoneyView(),
      ),
    );
  }

  FundingDraft draft({int amountKobo = 0}) => FundingDraft(
    amount: Money.fromKobo(amountKobo),
    balance: const Money.fromKobo(2500000),
  );

  setUp(() {
    cubit = _MockAddMoneyCubit();
    when(cubit.submit).thenAnswer((_) async {});
    when(() => cubit.amountChanged(any())).thenReturn(null);
  });

  testWidgets('it waits rather than rendering an empty form', (tester) async {
    await pump(tester, const AddMoneyState.initial());

    expect(find.byType(LoadingIndicator), findsOneWidget);
  });

  testWidgets('it shows the balance and asks for an amount', (tester) async {
    await pump(tester, AddMoneyState.editing(draft()));

    expect(find.text('Enter how much to add'), findsOneWidget);
    expect(find.text('Wallet balance'), findsOneWidget);
    expect(find.text('₦25,000.00'), findsWidgets);
  });

  testWidgets('nothing entered leaves the CTA dead and unnamed', (
    tester,
  ) async {
    await pump(tester, AddMoneyState.editing(draft()));

    final button = tester.widget<CustomButton>(find.byType(CustomButton));
    expect(button.label, 'Add money');
    expect(button.onPressed, isNull);
  });

  testWidgets('an amount names itself on the button and the balance ahead', (
    tester,
  ) async {
    await pump(tester, AddMoneyState.editing(draft(amountKobo: 500000)));

    expect(
      tester.widget<CustomButton>(find.byType(CustomButton)).label,
      'Add ₦5,000.00',
    );
    expect(find.text('Your balance becomes ₦30,000.00'), findsOneWidget);
    expect(find.text('₦30,000.00'), findsOneWidget);
  });

  testWidgets('over the top-up limit is named and blocks the CTA', (
    tester,
  ) async {
    await pump(tester, AddMoneyState.editing(draft(amountKobo: 60000000)));

    expect(
      find.text('One top-up cannot be more than ${kMaxTopUp.format()}'),
      findsOneWidget,
    );
    expect(
      tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
      isNull,
    );
  });

  testWidgets('a preset fills the amount without typing', (tester) async {
    await pump(tester, AddMoneyState.editing(draft()));

    await tester.tap(find.text('₦5,000.00'));

    verify(() => cubit.amountChanged('5,000.00')).called(1);
  });

  testWidgets('the button queues the top-up', (tester) async {
    await pump(tester, AddMoneyState.editing(draft(amountKobo: 500000)));

    await tester.tap(find.byType(CustomButton));
    verify(cubit.submit).called(1);
  });

  testWidgets('a refusal is shown as copy', (tester) async {
    await pump(tester, AddMoneyState.editing(draft(), error: 'Not enough'));

    expect(find.text('Not enough'), findsOneWidget);
  });

  testWidgets('submitting shows progress on the button', (tester) async {
    await pump(tester, AddMoneyState.submitting(draft(amountKobo: 500000)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('the receipt never claims the money has landed', (tester) async {
    await pump(tester, AddMoneyState.done(draft(amountKobo: 500000)));

    expect(find.text('On its way'), findsOneWidget);
    expect(find.textContaining('is queued for your wallet'), findsOneWidget);
  });

  testWidgets('Back to wallet leaves the flow', (tester) async {
    await pump(tester, AddMoneyState.done(draft(amountKobo: 500000)));

    await tester.tap(find.text('Back to wallet'));
    await tester.pumpAndSettle();

    expect(find.byType(AddMoneyView), findsNothing);
  });

  testWidgets('AddMoneyPage resolves its cubit and starts it', (tester) async {
    when(cubit.start).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<AddMoneyState>.empty(),
      initialState: const AddMoneyState.initial(),
    );
    sl.registerFactory<AddMoneyCubit>(() => cubit);
    addTearDown(sl.reset);

    await tester.pumpApp(const AddMoneyPage());

    expect(find.byType(AddMoneyView), findsOneWidget);
    verify(cubit.start).called(1);
  });
}
