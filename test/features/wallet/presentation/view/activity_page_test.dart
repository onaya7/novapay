import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:novapay/features/wallet/presentation/view/activity_page.dart';
import 'package:novapay/features/wallet/presentation/view/transaction_detail_page.dart';
import 'package:novapay/features/wallet/presentation/widgets/wallet_widgets.dart';

import '../../../../helpers/helpers.dart';

class _MockWalletCubit extends MockCubit<WalletState> implements WalletCubit;

ActivityItem _item(String id) => ActivityItem(
  id: id,
  title: 'To $id',
  amountKobo: -500000,
  occurredAt: DateTime.now(),
  status: ActivityStatus.settled,
);

void main() {
  late _MockWalletCubit cubit;

  Future<void> pumpView(WidgetTester tester, WalletState state) {
    whenListen(cubit, const Stream<WalletState>.empty(), initialState: state);
    return tester.pumpApp(
      BlocProvider<WalletCubit>.value(
        value: cubit,
        child: const ActivityView(),
      ),
    );
  }

  setUp(() {
    cubit = _MockWalletCubit();
    when(cubit.refresh).thenAnswer((_) async {});
  });

  testWidgets('the first frame is a skeleton, not a spinner', (tester) async {
    await pumpView(tester, const WalletState.loading());

    expect(find.byType(ActivitySkeleton), findsOneWidget);
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

  testWidgets('an empty history says so', (tester) async {
    await pumpView(
      tester,
      const WalletState.ready(
        WalletSnapshot(confirmedKobo: 24800000, pendingKobo: 0, activity: []),
      ),
    );

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byType(ActivityRow), findsNothing);
  });

  testWidgets('every row in the snapshot is listed, keyed per row', (
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
    expect(find.byType(ActivityRow), findsNWidgets(2));
    expect(
      tester.widget<ActivityRow>(find.byType(ActivityRow).first).key,
      const ValueKey('a'),
    );
  });

  testWidgets('tapping a row opens its transaction detail', (tester) async {
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

    await tester.tap(find.byType(ActivityRow));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailPage), findsOneWidget);
  });

  testWidgets('pulling down asks for a reload', (tester) async {
    await pumpView(
      tester,
      const WalletState.ready(
        WalletSnapshot(confirmedKobo: 24800000, pendingKobo: 0, activity: []),
      ),
    );

    await tester.fling(find.byType(AppEmptyState), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(cubit.refresh).called(1);
  });

  group('ActivityPage', () {
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
      await tester.pumpApp(const ActivityPage());

      expect(find.byType(ActivityView), findsOneWidget);
      verify(cubit.start).called(1);
    });
  });
}
