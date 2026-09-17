import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/app/app.dart';
import 'package:novapay/app/presentation/cubit/locale_cubit.dart';
import 'package:novapay/app/presentation/cubit/theme_cubit.dart';
import 'package:novapay/config/theme/app_theme.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/core/notifications/notification_service.dart';
import 'package:novapay/core/notifications/transfer_sync_notifier.dart';
import 'package:novapay/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:novapay/features/profile/presentation/view/profile_page.dart';
import 'package:novapay/features/savings/presentation/cubit/savings_cubit.dart';
import 'package:novapay/features/savings/presentation/view/savings_page.dart';
import 'package:novapay/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:novapay/features/wallet/presentation/view/activity_page.dart';
import 'package:novapay/features/wallet/presentation/view/wallet_page.dart';

class _MockWalletCubit extends MockCubit<WalletState> implements WalletCubit;

class _MockSavingsCubit extends MockCubit<SavingsState> implements SavingsCubit;

class _MockThemeCubit extends MockCubit<AppThemeMode> implements ThemeCubit;

class _MockLocaleCubit extends MockCubit<AppLocale> implements LocaleCubit;

class _MockProfileCubit extends MockCubit<ProfileState> implements ProfileCubit;

class _MockNotificationService extends Mock implements NotificationService;

class _MockTransferSyncNotifier extends Mock implements TransferSyncNotifier;

void main() {
  setUp(() {
    final wallet = _MockWalletCubit();
    when(wallet.start).thenAnswer((_) async {});
    when(wallet.refresh).thenAnswer((_) async {});
    whenListen(
      wallet,
      const Stream<WalletState>.empty(),
      initialState: const WalletState.loading(),
    );
    sl.registerFactory<WalletCubit>(() => wallet);

    final savings = _MockSavingsCubit();
    when(savings.start).thenAnswer((_) async {});
    when(savings.refresh).thenAnswer((_) async {});
    whenListen(
      savings,
      const Stream<SavingsState>.empty(),
      initialState: const SavingsState.loading(),
    );
    sl.registerFactory<SavingsCubit>(() => savings);

    final theme = _MockThemeCubit();
    whenListen(
      theme,
      const Stream<AppThemeMode>.empty(),
      initialState: AppThemeMode.system,
    );
    sl.registerFactory<ThemeCubit>(() => theme);

    final profile = _MockProfileCubit();
    when(profile.start).thenAnswer((_) async {});
    whenListen(
      profile,
      const Stream<ProfileState>.empty(),
      initialState: const ProfileState.loading(),
    );
    sl.registerFactory<ProfileCubit>(() => profile);

    final locale = _MockLocaleCubit();
    whenListen(
      locale,
      const Stream<AppLocale>.empty(),
      initialState: AppLocale.system,
    );
    sl.registerFactory<LocaleCubit>(() => locale);

    final notifications = _MockNotificationService();
    when(notifications.initialize).thenAnswer((_) async {});
    sl.registerFactory<NotificationService>(() => notifications);

    final transferSyncNotifier = _MockTransferSyncNotifier();
    when(transferSyncNotifier.start).thenAnswer((_) async {});
    when(transferSyncNotifier.dispose).thenAnswer((_) async {});
    sl.registerFactory<TransferSyncNotifier>(() => transferSyncNotifier);
  });

  tearDown(sl.reset);

  group('App', () {
    testWidgets('opens on the wallet', (tester) async {
      // A const instance is canonicalized, so the constructor never runs.
      // ignore: prefer_const_constructors
      await tester.pumpWidget(App());

      expect(find.byType(WalletPage), findsOneWidget);
    });

    testWidgets('every tab is reachable from the nav bar', (tester) async {
      // Every tab starts loading, and loading is a spinner that never stops
      // animating, so this pumps rather than settling.
      await tester.pumpWidget(const App());

      await tester.tap(find.text('Savings'));
      await tester.pump();
      expect(find.byType(SavingsPage), findsOneWidget);

      await tester.tap(find.text('Activity'));
      await tester.pump();
      expect(find.byType(ActivityPage), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pump();
      expect(find.byType(ProfilePage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
      await tester.pump();
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
