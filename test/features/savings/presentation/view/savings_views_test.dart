import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/savings/domain/entities/contribution_draft.dart';
import 'package:novapay/features/savings/domain/entities/goal_draft.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/presentation/cubit/contribute_cubit.dart';
import 'package:novapay/features/savings/presentation/cubit/create_goal_cubit.dart';
import 'package:novapay/features/savings/presentation/cubit/savings_cubit.dart';
import 'package:novapay/features/savings/presentation/view/contribute_page.dart';
import 'package:novapay/features/savings/presentation/view/create_goal_page.dart';
import 'package:novapay/features/savings/presentation/view/savings_page.dart';
import 'package:novapay/features/savings/presentation/widgets/savings_widgets.dart';

import '../../../../helpers/helpers.dart';

class _MockSavingsCubit extends MockCubit<SavingsState> implements SavingsCubit;

class _MockCreateGoalCubit extends MockCubit<CreateGoalState>
    implements CreateGoalCubit;

class _MockContributeCubit extends MockCubit<ContributeState>
    implements ContributeCubit;

SavingsGoalItem _goal({
  String id = 'g1',
  String name = 'Rent',
  int savedKobo = 2500000,
  int pendingKobo = 0,
}) => SavingsGoalItem(
  id: id,
  name: name,
  targetKobo: 10000000,
  savedKobo: savedKobo,
  pendingKobo: pendingKobo,
  targetDate: DateTime.now().add(const Duration(days: 30)),
);

/// Reads through the union, not the variant: a variant's own field would
/// shadow the getter the screen actually calls.
ContributionDraft? _draftOf(ContributeState state) => state.draft;

void main() {
  setUpAll(() => registerFallbackValue(_goal()));

  group('SavingsView', () {
    late _MockSavingsCubit cubit;

    Future<void> pump(WidgetTester tester, SavingsState state) {
      whenListen(
        cubit,
        const Stream<SavingsState>.empty(),
        initialState: state,
      );
      return tester.pumpApp(
        BlocProvider<SavingsCubit>.value(
          value: cubit,
          child: const SavingsView(),
        ),
      );
    }

    setUp(() {
      cubit = _MockSavingsCubit();
      when(cubit.refresh).thenAnswer((_) async {});
    });

    testWidgets('the first frame is a skeleton, not a spinner', (tester) async {
      await pump(tester, const SavingsState.loading());

      expect(find.byType(SavingsSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failure offers the way out', (tester) async {
      await pump(tester, const SavingsState.failure('We could not reach it.'));

      await tester.tap(find.text('Try again'));
      verify(cubit.refresh).called(1);
    });

    testWidgets('no goals explains what a goal is', (tester) async {
      await pump(tester, const SavingsState.ready([]));

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.byType(GoalCard), findsNothing);
      expect(find.text('Create goal'), findsOneWidget);
    });

    testWidgets('goals render as keyed cards', (tester) async {
      await pump(
        tester,
        SavingsState.ready([_goal(), _goal(id: 'g2', name: 'Trip')]),
      );

      expect(find.byType(GoalCard), findsNWidgets(2));
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Trip'), findsOneWidget);
      expect(
        tester.widget<GoalCard>(find.byType(GoalCard).first).key,
        const ValueKey('g1'),
      );
    });

    testWidgets('pulling down asks for a reload', (tester) async {
      await pump(tester, SavingsState.ready([_goal()]));

      await tester.fling(find.byType(GoalCard), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(cubit.refresh).called(1);
    });

    testWidgets('Create goal opens the form, then reloads on return', (
      tester,
    ) async {
      final create = _MockCreateGoalCubit();
      whenListen(
        create,
        const Stream<CreateGoalState>.empty(),
        initialState: const CreateGoalState.editing(GoalDraft()),
      );
      sl.registerFactory<CreateGoalCubit>(() => create);
      addTearDown(sl.reset);

      await pump(tester, const SavingsState.ready([]));
      await tester.tap(find.text('Create goal'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateGoalView), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      verify(cubit.refresh).called(1);
    });

    testWidgets('tapping a goal opens contribute, then reloads on return', (
      tester,
    ) async {
      final contribute = _MockContributeCubit();
      when(() => contribute.start(any())).thenAnswer((_) async {});
      // Editing, not initial: the initial state runs a spinner, and
      // pumpAndSettle never settles while an animation is in flight.
      whenListen(
        contribute,
        const Stream<ContributeState>.empty(),
        initialState: ContributeState.editing(ContributionDraft(goal: _goal())),
      );
      sl.registerFactory<ContributeCubit>(() => contribute);
      addTearDown(sl.reset);

      await pump(tester, SavingsState.ready([_goal()]));
      await tester.tap(find.text('Rent'));
      await tester.pumpAndSettle();

      expect(find.byType(ContributeView), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      verify(cubit.refresh).called(1);
    });
  });

  group('ContributeState', () {
    final draft = ContributionDraft(goal: _goal());

    test('every phase but the first carries the draft', () {
      expect(_draftOf(const ContributeState.initial()), isNull);
      expect(_draftOf(ContributeState.editing(draft)), draft);
      expect(_draftOf(ContributeState.submitting(draft)), draft);
      expect(_draftOf(ContributeState.done(draft)), draft);
    });

    test('only submitting reports itself as in flight', () {
      expect(ContributeState.submitting(draft).isSubmitting, isTrue);
      expect(ContributeState.editing(draft).isSubmitting, isFalse);
      expect(const ContributeState.initial().isSubmitting, isFalse);
    });
  });

  group('GoalCard', () {
    testWidgets('prints the percentage beside the bar', (tester) async {
      await tester.pumpApp(GoalCard(goal: _goal(), onTap: () {}));

      expect(find.text('25%'), findsOneWidget);
      expect(find.text('₦25,000.00 of ₦100,000.00'), findsOneWidget);
      expect(find.text('Due in 30 days'), findsOneWidget);
    });

    testWidgets('a queued contribution is annotated', (tester) async {
      await tester.pumpApp(
        GoalCard(goal: _goal(pendingKobo: 2500000), onTap: () {}),
      );

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('a reached goal says so instead', (tester) async {
      await tester.pumpApp(
        GoalCard(goal: _goal(savedKobo: 10000000), onTap: () {}),
      );

      expect(find.text('Reached'), findsOneWidget);
      expect(find.text('Goal reached'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('tapping it opens the goal', (tester) async {
      var taps = 0;
      await tester.pumpApp(GoalCard(goal: _goal(), onTap: () => taps++));

      await tester.tap(find.text('Rent'));
      expect(taps, 1);
    });

    testWidgets('a missed target date is warned, not just stated', (
      tester,
    ) async {
      final overdue = SavingsGoalItem(
        id: 'g1',
        name: 'Rent',
        targetKobo: 10000000,
        savedKobo: 0,
        targetDate: DateTime.now().subtract(const Duration(days: 2)),
      );
      await tester.pumpApp(GoalCard(goal: overdue, onTap: () {}));

      expect(
        tester.widget<Text>(find.text('Target date passed')).style?.color,
        AppThemeColors.light.warning,
      );
    });
  });

  group('GoalDateField', () {
    testWidgets('it prompts until a date is chosen', (tester) async {
      await tester.pumpApp(GoalDateField(value: null, onChanged: (_) {}));

      expect(find.text('Choose a date'), findsOneWidget);
    });

    testWidgets('a chosen date is shown in full', (tester) async {
      await tester.pumpApp(
        GoalDateField(value: DateTime(2027, 12, 25), onChanged: (_) {}),
      );

      expect(find.text('25 Dec 2027'), findsOneWidget);
    });

    testWidgets('tapping opens a picker that cannot choose the past', (
      tester,
    ) async {
      DateTime? chosen;
      await tester.pumpApp(
        GoalDateField(value: null, onChanged: (value) => chosen = value),
      );

      await tester.tap(find.text('Choose a date'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(chosen, isNotNull);
      expect(chosen!.isBefore(DateTime.now()), isFalse);
    });

    testWidgets('dismissing the picker changes nothing', (tester) async {
      var calls = 0;
      await tester.pumpApp(
        GoalDateField(value: null, onChanged: (_) => calls++),
      );

      await tester.tap(find.text('Choose a date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(calls, 0);
    });
  });

  group('CreateGoalView', () {
    late _MockCreateGoalCubit cubit;

    Future<void> pump(WidgetTester tester, CreateGoalState state) {
      whenListen(
        cubit,
        const Stream<CreateGoalState>.empty(),
        initialState: state,
      );
      return tester.pumpApp(
        BlocProvider<CreateGoalCubit>.value(
          value: cubit,
          child: const CreateGoalView(),
        ),
      );
    }

    setUp(() {
      cubit = _MockCreateGoalCubit();
      when(cubit.submit).thenAnswer((_) async {});
      when(() => cubit.nameChanged(any())).thenReturn(null);
      when(() => cubit.targetChanged(any())).thenReturn(null);
      when(() => cubit.dateChanged(any())).thenReturn(null);
    });

    testWidgets('asks for all three, with visible labels', (tester) async {
      await pump(tester, const CreateGoalState.editing(GoalDraft()));

      expect(find.text('What are you saving for?'), findsOneWidget);
      expect(find.text('Target amount'), findsOneWidget);
      expect(find.text('Target date'), findsOneWidget);
      expect(find.text('Choose a date'), findsOneWidget);
    });

    testWidgets('an incomplete draft leaves the CTA dead', (tester) async {
      await pump(tester, const CreateGoalState.editing(GoalDraft()));

      expect(
        tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
        isNull,
      );
    });

    testWidgets('a complete draft creates on tap', (tester) async {
      await pump(
        tester,
        CreateGoalState.editing(
          GoalDraft(
            name: 'Rent',
            target: const Money.fromKobo(100),
            targetDate: DateTime(2027, 3, 4),
          ),
        ),
      );

      expect(find.text('4 Mar 2027'), findsOneWidget);
      await tester.tap(find.byType(CustomButton));
      verify(cubit.submit).called(1);
    });

    testWidgets('typing reaches the cubit', (tester) async {
      await pump(tester, const CreateGoalState.editing(GoalDraft()));

      await tester.enterText(find.byType(TextField).first, 'Rent');
      verify(() => cubit.nameChanged('Rent')).called(1);
    });

    testWidgets('a refusal is shown as copy', (tester) async {
      await pump(
        tester,
        const CreateGoalState.editing(GoalDraft(), error: 'Give it a name'),
      );

      expect(find.text('Give it a name'), findsOneWidget);
    });

    testWidgets('a created goal leaves the form', (tester) async {
      whenListen(
        cubit,
        Stream<CreateGoalState>.value(const CreateGoalState.done(GoalDraft())),
        initialState: const CreateGoalState.editing(GoalDraft()),
      );
      await tester.pumpApp(
        BlocProvider<CreateGoalCubit>.value(
          value: cubit,
          child: const CreateGoalView(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CreateGoalView), findsNothing);
    });

    testWidgets('submitting shows progress on the button', (tester) async {
      await pump(tester, const CreateGoalState.submitting(GoalDraft()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ContributeView', () {
    late _MockContributeCubit cubit;

    Future<void> pump(WidgetTester tester, ContributeState state) {
      whenListen(
        cubit,
        const Stream<ContributeState>.empty(),
        initialState: state,
      );
      return tester.pumpApp(
        BlocProvider<ContributeCubit>.value(
          value: cubit,
          child: const ContributeView(),
        ),
      );
    }

    ContributionDraft draft({int amountKobo = 0}) => ContributionDraft(
      goal: _goal(),
      amount: Money.fromKobo(amountKobo),
      available: const Money.fromKobo(2000000),
    );

    setUp(() {
      cubit = _MockContributeCubit();
      when(cubit.submit).thenAnswer((_) async {});
      when(() => cubit.amountChanged(any())).thenReturn(null);
    });

    testWidgets('it waits rather than rendering an empty form', (tester) async {
      await pump(tester, const ContributeState.initial());

      expect(find.byType(LoadingIndicator), findsOneWidget);
    });

    testWidgets('it shows the goal and where it stands', (tester) async {
      await pump(tester, ContributeState.editing(draft()));

      expect(find.byType(GoalSummaryHeader), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Enter how much to add'), findsOneWidget);
    });

    testWidgets('nothing entered leaves the CTA dead and unnamed', (
      tester,
    ) async {
      await pump(tester, ContributeState.editing(draft()));

      final button = tester.widget<CustomButton>(find.byType(CustomButton));
      expect(button.label, 'Add to goal');
      expect(button.onPressed, isNull);
    });

    testWidgets('an affordable amount names itself on the button', (
      tester,
    ) async {
      await pump(tester, ContributeState.editing(draft(amountKobo: 500000)));

      expect(
        tester.widget<CustomButton>(find.byType(CustomButton)).label,
        'Add ₦5,000.00',
      );
      expect(find.text('₦15,000.00 left in your wallet'), findsOneWidget);
    });

    testWidgets('too much is named and blocks the CTA', (tester) async {
      await pump(tester, ContributeState.editing(draft(amountKobo: 9999999)));

      expect(find.text('That is more than you have available'), findsOneWidget);
      expect(
        tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
        isNull,
      );
    });

    testWidgets('a preset fills the amount without typing', (tester) async {
      await pump(tester, ContributeState.editing(draft()));

      await tester.tap(find.text('₦5,000.00'));

      verify(() => cubit.amountChanged('5,000.00')).called(1);
    });

    testWidgets('the button queues the contribution', (tester) async {
      await pump(tester, ContributeState.editing(draft(amountKobo: 500000)));

      await tester.tap(find.byType(CustomButton));
      verify(cubit.submit).called(1);
    });

    testWidgets('a refusal is shown as copy', (tester) async {
      await pump(tester, ContributeState.editing(draft(), error: 'Not enough'));

      expect(find.text('Not enough'), findsOneWidget);
    });

    testWidgets('submitting shows progress on the button', (tester) async {
      await pump(tester, ContributeState.submitting(draft(amountKobo: 500000)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('the receipt never claims the money has landed', (
      tester,
    ) async {
      await pump(tester, ContributeState.done(draft(amountKobo: 500000)));

      expect(find.text('On its way'), findsOneWidget);
      expect(find.text('Queued'), findsOneWidget);
      expect(find.textContaining('is queued for Rent'), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets('Back to goals leaves the flow', (tester) async {
      await pump(tester, ContributeState.done(draft(amountKobo: 500000)));

      await tester.tap(find.text('Back to goals'));
      await tester.pumpAndSettle();

      expect(find.byType(ContributeView), findsNothing);
    });
  });

  group('pages resolve their cubits', () {
    testWidgets('SavingsPage starts its cubit', (tester) async {
      final cubit = _MockSavingsCubit();
      when(cubit.start).thenAnswer((_) async {});
      when(cubit.refresh).thenAnswer((_) async {});
      whenListen(
        cubit,
        const Stream<SavingsState>.empty(),
        initialState: const SavingsState.loading(),
      );
      sl.registerFactory<SavingsCubit>(() => cubit);
      addTearDown(sl.reset);

      // A const instance is canonicalized, so the constructor never runs.
      // ignore: prefer_const_constructors
      await tester.pumpApp(SavingsPage());

      expect(find.byType(SavingsView), findsOneWidget);
      verify(cubit.start).called(1);
    });

    testWidgets('CreateGoalPage resolves its cubit', (tester) async {
      final cubit = _MockCreateGoalCubit();
      whenListen(
        cubit,
        const Stream<CreateGoalState>.empty(),
        initialState: const CreateGoalState.editing(GoalDraft()),
      );
      sl.registerFactory<CreateGoalCubit>(() => cubit);
      addTearDown(sl.reset);

      await tester.pumpApp(const CreateGoalPage());

      expect(find.byType(CreateGoalView), findsOneWidget);
    });

    testWidgets('ContributePage starts its cubit with the goal', (
      tester,
    ) async {
      final cubit = _MockContributeCubit();
      when(() => cubit.start(any())).thenAnswer((_) async {});
      whenListen(
        cubit,
        const Stream<ContributeState>.empty(),
        initialState: const ContributeState.initial(),
      );
      sl.registerFactory<ContributeCubit>(() => cubit);
      addTearDown(sl.reset);

      await tester.pumpApp(ContributePage(goal: _goal()));

      expect(find.byType(ContributeView), findsOneWidget);
      verify(() => cubit.start(any())).called(1);
    });
  });
}
