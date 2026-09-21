import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/presentation/cubit/locale_cubit.dart';
import 'package:novapay/app/presentation/cubit/theme_cubit.dart';
import 'package:novapay/app/routes/routes_generator.dart';
import 'package:novapay/config/theme/app_theme.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:novapay/l10n/l10n.dart';

/// The three cubits here are app-wide: the theme paints every screen, and the
/// profile name is read by the wallet greeting as well as the profile screen.
/// All of them, and the notification pipeline, are started in `bootstrap()`
/// before this widget exists, and outlive it for the life of the process.
class App extends StatefulWidget {
  const new({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final ThemeCubit _theme = sl<ThemeCubit>();
  final LocaleCubit _locale = sl<LocaleCubit>();
  final ProfileCubit _profile = sl<ProfileCubit>();

  // Built once and held here, not inline in build(): a fresh GoRouter on
  // every theme toggle would reset navigation back to the initial route.
  final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: _theme),
        BlocProvider<LocaleCubit>.value(value: _locale),
        BlocProvider<ProfileCubit>.value(value: _profile),
      ],
      child: AppView(router: _router),
    );
  }
}

class AppView extends StatelessWidget {
  const new({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state;
    return BlocBuilder<ThemeCubit, AppThemeMode>(
      builder: (context, mode) => MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode.asThemeMode,
        locale: locale.asLocale,
        // material_ui has its own MaterialLocalizations, separate from
        // Flutter's; its auto-added fallback covers English only, so every
        // other supported locale needs its multi-locale delegates too.
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}

extension AppThemeModeX on AppThemeMode {
  ThemeMode get asThemeMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  /// The word on the toggle.
  String label(AppLocalizations l10n) => switch (this) {
    AppThemeMode.system => l10n.systemLabel,
    AppThemeMode.light => l10n.lightLabel,
    AppThemeMode.dark => l10n.darkLabel,
  };
}

extension AppLocaleX on AppLocale {
  /// Null follows the device locale, same as `AppThemeMode.system` for theme.
  Locale? get asLocale => switch (this) {
    AppLocale.system => null,
    AppLocale.en => const Locale('en'),
    AppLocale.es => const Locale('es'),
    AppLocale.fr => const Locale('fr'),
  };

  /// The word on the toggle. A language names itself, in its own spelling,
  /// regardless of the app's current language — the standard convention, so
  /// it stays findable even to someone who can't read the active locale.
  String label(AppLocalizations l10n) => switch (this) {
    AppLocale.system => l10n.systemLabel,
    AppLocale.en => 'English',
    AppLocale.es => 'Español',
    AppLocale.fr => 'Français',
  };
}
