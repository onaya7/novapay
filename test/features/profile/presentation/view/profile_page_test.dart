import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/app/presentation/cubit/locale_cubit.dart';
import 'package:novapay/app/presentation/cubit/theme_cubit.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/features/profile/domain/entities/user_profile.dart';
import 'package:novapay/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:novapay/features/profile/presentation/view/profile_page.dart';

import '../../../../helpers/helpers.dart';

class _MockProfileCubit extends MockCubit<ProfileState> implements ProfileCubit;

class _MockThemeCubit extends MockCubit<AppThemeMode> implements ThemeCubit;

class _MockLocaleCubit extends MockCubit<AppLocale> implements LocaleCubit;

void main() {
  late _MockProfileCubit profile;
  late _MockThemeCubit theme;
  late _MockLocaleCubit locale;

  Future<void> pump(WidgetTester tester, ProfileState state) {
    whenListen(
      profile,
      const Stream<ProfileState>.empty(),
      initialState: state,
    );
    return tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profile),
          BlocProvider<ThemeCubit>.value(value: theme),
          BlocProvider<LocaleCubit>.value(value: locale),
        ],
        child: const ProfileView(),
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(AppThemeMode.system);
    registerFallbackValue(AppLocale.system);
  });

  setUp(() {
    profile = _MockProfileCubit();
    theme = _MockThemeCubit();
    locale = _MockLocaleCubit();
    whenListen(
      theme,
      const Stream<AppThemeMode>.empty(),
      initialState: AppThemeMode.system,
    );
    whenListen(
      locale,
      const Stream<AppLocale>.empty(),
      initialState: AppLocale.system,
    );
    when(() => theme.setMode(any())).thenAnswer((_) async {});
    when(() => locale.setLocale(any())).thenAnswer((_) async {});
    when(() => profile.rename(any())).thenAnswer((_) async {});
    when(profile.start).thenAnswer((_) async {});
  });

  testWidgets('loading shows a spinner, not an empty screen', (tester) async {
    await pump(tester, const ProfileState.loading());

    expect(find.byType(LoadingIndicator), findsOneWidget);
  });

  testWidgets('a failure offers a way to retry', (tester) async {
    await pump(
      tester,
      const ProfileState.failure('We could not reach NovaPay.'),
    );

    expect(find.text('We could not reach NovaPay.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(profile.start).called(1);
  });

  testWidgets('no name yet invites one, rather than showing blank', (
    tester,
  ) async {
    await pump(tester, const ProfileState.ready(UserProfile()));

    expect(find.text('Add your name'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
  });

  testWidgets('a saved name is shown and edits reach the cubit', (
    tester,
  ) async {
    await pump(
      tester,
      const ProfileState.ready(UserProfile(displayName: 'Ada Lovelace')),
    );

    expect(find.text('Ada Lovelace'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Ada L');

    verify(() => profile.rename('Ada L')).called(1);
  });

  testWidgets('the About section names the money model and version', (
    tester,
  ) async {
    await pump(tester, const ProfileState.ready(UserProfile()));

    expect(find.text('Version'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('Held as whole kobo'), findsOneWidget);
  });

  testWidgets('the theme toggle switches mode', (tester) async {
    await pump(tester, const ProfileState.ready(UserProfile()));

    await tester.tap(find.text('Dark'));

    verify(() => theme.setMode(AppThemeMode.dark)).called(1);
  });

  testWidgets('the language toggle switches locale', (tester) async {
    await pump(tester, const ProfileState.ready(UserProfile()));
    await tester.ensureVisible(find.text('French'));

    await tester.tap(find.text('French'));

    verify(() => locale.setLocale(AppLocale.fr)).called(1);
  });

  testWidgets('ProfilePage renders the view', (tester) async {
    whenListen(
      profile,
      const Stream<ProfileState>.empty(),
      initialState: const ProfileState.loading(),
    );
    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profile),
          BlocProvider<ThemeCubit>.value(value: theme),
        ],
        child: const ProfilePage(),
      ),
    );

    expect(find.byType(ProfileView), findsOneWidget);
  });
}
