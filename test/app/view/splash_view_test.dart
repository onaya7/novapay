import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/app/presentation/cubit/splash_cubit.dart';
import 'package:novapay/app/view/splash_view.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/injections/injection.dart';

import '../../helpers/helpers.dart';

class _MockSplashCubit extends MockCubit<SplashStatus> implements SplashCubit;

void main() {
  late _MockSplashCubit cubit;

  setUp(() {
    cubit = _MockSplashCubit();
    when(cubit.start).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<SplashStatus>.empty(),
      initialState: SplashStatus.preparing,
    );
    sl.registerFactory<SplashCubit>(() => cubit);
  });

  tearDown(sl.reset);

  testWidgets('starts the warm-up as soon as it is built', (tester) async {
    await tester.pumpApp(const SplashView());

    verify(cubit.start).called(1);
  });

  testWidgets('shows the wordmark on brand, edge to edge', (tester) async {
    await tester.pumpApp(const SplashView());

    expect(tester.widget<Image>(find.byType(Image)).semanticLabel, 'Novapay');
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColor.brand,
    );
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).appBar, isNull);
  });

  testWidgets('the wordmark matches the width the launch screen uses', (
    tester,
  ) async {
    await tester.pumpApp(const SplashView());

    expect(
      tester.widget<Image>(find.byType(Image)).width,
      SplashView.wordmarkWidth,
    );
  });

  testWidgets('stays put while the wallet is still warming', (tester) async {
    await tester.pumpApp(const SplashView());
    await tester.pump(SplashCubit.budget);

    expect(find.byType(SplashView), findsOneWidget);
  });

  testWidgets('the entrance runs and settles', (tester) async {
    await tester.pumpApp(const SplashView());

    final opacity = tester.widget<FadeTransition>(find.byType(FadeTransition));
    expect(opacity.opacity.value, lessThan(1));

    await tester.pump(SplashCubit.minimumHold);
    expect(opacity.opacity.value, 1);
  });
}
