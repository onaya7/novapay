import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/app/presentation/cubit/nav_cubit.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/funding/domain/entities/funding_draft.dart';
import 'package:novapay/features/funding/presentation/cubit/add_money_cubit.dart';
import 'package:novapay/features/funding/presentation/view/add_money_page.dart';
import 'package:novapay/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_draft.dart';
import 'package:novapay/features/send_money/presentation/cubit/send_money_cubit.dart';
import 'package:novapay/features/send_money/presentation/view/send_money_page.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:novapay/features/wallet/presentation/view/wallet_page.dart';
import 'package:novapay/features/wallet/presentation/widgets/wallet_widgets.dart';

import '../../../../helpers/helpers.dart';

class _MockWalletCubit extends MockCubit<WalletState> implements WalletCubit;

class _MockSendMoneyCubit extends MockCubit<SendMoneyState>
    implements SendMoneyCubit;

class _MockProfileCubit extends MockCubit<ProfileState> implements ProfileCubit;

class _MockAddMoneyCubit extends MockCubit<AddMoneyState>
    implements AddMoneyCubit;

ActivityItem _item(String id) => ActivityItem(
  id: id,
  title: 'To $id',
  amountKobo: -500000,
  occurredAt: DateTime.now(),
  status: ActivityStatus.settled,
);

void main() {
  late _MockWalletCubit cubit;
  late _MockProfileCubit profile;
  late NavCubit nav;

  Future<void> pumpView(WidgetTester tester, WalletState state) {
    whenListen(cubit, const Stream<WalletState>.empty(), initialState: state);
    return tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<WalletCubit>.value(value: cubit),
          BlocProvider<ProfileCubit>.value(value: profile),
          BlocProvider<NavCubit>.value(value: nav),
        ],
        child: const WalletView(),
      ),
    );
  }

  setUp(() {
    cubit = _MockWalletCubit();
    when(cubit.refresh).thenAnswer((_) async {});
    profile = _MockProfileCubit();
    whenListen(
      profile,
      const Stream<ProfileState>.empty(),
      initialState: const ProfileState.loading(),
    );
    nav = NavCubit();
    addTearDown(nav.close);
  });

  testWidgets('the wallet is a root screen, so it offers no back', (
    tester,
  ) async {
    await pumpView(
      tester,
      const WalletState.ready(
        WalletSnapshot(confirmedKobo: 24800000, pendingKobo: 0, activity: []),
      ),
    );

    expect(find.text('Wallet'), findsOneWidget);
    expect(find.byType(WalletHeader), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('the first frame is a skeleton, not a spinner', (tester) async {
    await pumpView(tester, const WalletState.loading());

    expect(find.byType(WalletSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a failure offers the way out', (tester) async {
    await pumpView(
      tester,
      const WalletState.failure('We could not reach NovaPay.'),
    );

    expect(find.text('We could not reach NovaPay.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(cubit.refresh).called(1);
  });

  testWidgets('an empty wallet still shows the balance and a next step', (
    tester,
  ) async {
    await pumpView(
      tester,
      const WalletState.ready(
        WalletSnapshot(confirmedKobo: 24800000, pendingKobo: 0, activity: []),
      ),
    );

    expect(find.byType(BalanceCard), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byType(ActivityRow), findsNothing);
  });

  testWidgets('activity renders through a builder, keyed per row', (
    tester,
  ) async {
    await pumpView(
      tester,
      WalletState.ready(
        WalletSnapshot(
          confirmedKobo: 24800000,
          pendingKobo: 0,
          activity: [_item('a'), _item('b')],
        ),
      ),
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(BalanceCard), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.byType(ActivityRow), findsNWidgets(2));
    expect(
      tester.widget<ActivityRow>(find.byType(ActivityRow).first).key,
      const ValueKey('a'),
    );
  });

  testWidgets('See all switches to the Activity tab', (tester) async {
    await pumpView(
      tester,
      WalletState.ready(
        WalletSnapshot(
          confirmedKobo: 24800000,
          pendingKobo: 0,
          activity: [_item('a')],
        ),
      ),
    );

    await tester.tap(find.text('See all'));

    expect(nav.state, 2);
  });

  testWidgets('Add money opens the funding flow', (tester) async {
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
      const WalletState.ready(
        WalletSnapshot(confirmedKobo: 24800000, pendingKobo: 0, activity: []),
      ),
    );

    await tester.tap(find.text('Add money'));
    await tester.pumpAndSettle();

    expect(find.byType(AddMoneyView), findsOneWidget);
  });

  testWidgets('the primary action opens Send Money', (tester) async {
    final sendCubit = _MockSendMoneyCubit();
    when(sendCubit.start).thenAnswer((_) async {});
    whenListen(
      sendCubit,
      const Stream<SendMoneyState>.empty(),
      initialState: const SendMoneyState.editing(TransferDraft()),
    );
    sl.registerFactory<SendMoneyCubit>(() => sendCubit);
    addTearDown(sl.reset);

    await pumpView(
      tester,
      const WalletState.ready(
        WalletSnapshot(confirmedKobo: 24800000, pendingKobo: 0, activity: []),
      ),
    );

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(find.byType(SendMoneyView), findsOneWidget);
  });

  testWidgets('Save switches to the Savings tab', (tester) async {
    await pumpView(
      tester,
      const WalletState.ready(
        WalletSnapshot(confirmedKobo: 24800000, pendingKobo: 0, activity: []),
      ),
    );

    await tester.tap(find.text('Save'));

    expect(nav.state, 1);
  });

  testWidgets('History switches to the Activity tab', (tester) async {
    await pumpView(
      tester,
      const WalletState.ready(
        WalletSnapshot(confirmedKobo: 24800000, pendingKobo: 0, activity: []),
      ),
    );

    await tester.tap(find.text('History'));

    expect(nav.state, 2);
  });

  testWidgets('pulling down asks for a reload', (tester) async {
    await pumpView(
      tester,
      const WalletState.ready(
        WalletSnapshot(confirmedKobo: 24800000, pendingKobo: 0, activity: []),
      ),
    );

    await tester.fling(find.byType(BalanceCard), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(cubit.refresh).called(1);
  });

  group('WalletPage', () {
    setUp(() {
      sl.registerFactory<WalletCubit>(() => cubit);
      when(cubit.start).thenAnswer((_) async {});
      whenListen(
        cubit,
        const Stream<WalletState>.empty(),
        initialState: const WalletState.loading(),
      );
    });

    tearDown(sl.reset);

    testWidgets('resolves its cubit and starts it', (tester) async {
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<ProfileCubit>.value(value: profile),
            BlocProvider<NavCubit>.value(value: nav),
          ],
          child: const WalletPage(),
        ),
      );

      expect(find.byType(WalletView), findsOneWidget);
      verify(cubit.start).called(1);
    });
  });
}
