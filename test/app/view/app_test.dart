import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/app/app.dart';
import 'package:novapay/config/theme/app_theme.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:novapay/features/wallet/presentation/view/wallet_page.dart';

class _MockWalletCubit extends MockCubit<WalletState> implements WalletCubit;

void main() {
  late _MockWalletCubit cubit;

  setUp(() {
    cubit = _MockWalletCubit();
    when(cubit.start).thenAnswer((_) async {});
    when(cubit.refresh).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<WalletState>.empty(),
      initialState: const WalletState.loading(),
    );
    sl.registerFactory<WalletCubit>(() => cubit);
  });

  tearDown(sl.reset);

  group('App', () {
    testWidgets('opens on the wallet', (tester) async {
      // A const instance is canonicalized, so the constructor never runs.
      // ignore: prefer_const_constructors
      await tester.pumpWidget(App());

      expect(find.byType(WalletPage), findsOneWidget);
    });

    testWidgets('ships both themes, each carrying its roles', (tester) async {
      await tester.pumpWidget(const App());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme, AppTheme.light);
      expect(app.theme?.extension<AppThemeColors>(), AppThemeColors.light);
      expect(app.darkTheme?.extension<AppThemeColors>(), AppThemeColors.dark);
    });
  });
}
