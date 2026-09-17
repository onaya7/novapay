import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/presentation/cubit/theme_cubit.dart';
import 'package:novapay/app/routes/routes_generator.dart';
import 'package:novapay/config/theme/app_theme.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:novapay/l10n/l10n.dart';

/// Both cubits here are app-wide: the theme paints every screen, and the
/// profile name is read by the wallet greeting as well as the profile screen.
class App extends StatefulWidget {
  const new({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final ThemeCubit _theme = sl<ThemeCubit>();
  final ProfileCubit _profile = sl<ProfileCubit>();

  // Built once and held here, not inline in build(): a fresh GoRouter on
  // every theme toggle would reset navigation back to the initial route.
  final GoRouter _router = buildRouter();

  @override
  void initState() {
    super.initState();
    // Once, not per screen: two tabs read the same name.
    unawaited(_profile.start());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: _theme),
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
    return BlocBuilder<ThemeCubit, AppThemeMode>(
      builder: (context, mode) => MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode.asThemeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
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
  String get label => switch (this) {
    AppThemeMode.system => 'System',
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
  };
}
