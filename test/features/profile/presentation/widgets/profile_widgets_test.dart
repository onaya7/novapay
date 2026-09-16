import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/app/presentation/cubit/theme_cubit.dart';
import 'package:novapay/features/profile/presentation/widgets/profile_widgets.dart';

import '../../../../helpers/helpers.dart';

class _MockThemeCubit extends MockCubit<AppThemeMode> implements ThemeCubit;

void main() {
  group('SettingsRow', () {
    testWidgets('a plain row shows only its label', (tester) async {
      await tester.pumpApp(const SettingsRow(label: 'Version'));

      expect(find.text('Version'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('a value renders as the trailing detail', (tester) async {
      await tester.pumpApp(const SettingsRow(label: 'Version', value: '1.0.0'));

      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('a trailing widget renders after the value', (tester) async {
      await tester.pumpApp(
        const SettingsRow(label: 'Sync', trailing: Icon(Icons.check)),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('a row with onTap gets a chevron and fires', (tester) async {
      var taps = 0;
      await tester.pumpApp(SettingsRow(label: 'Manage', onTap: () => taps++));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(find.text('Manage'));
      expect(taps, 1);
    });
  });

  group('SettingsGroup', () {
    testWidgets('shows its title above its children', (tester) async {
      await tester.pumpApp(
        const SettingsGroup(
          title: 'ABOUT',
          children: [SettingsRow(label: 'Version', value: '1.0.0')],
        ),
      );

      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
    });
  });

  group('ThemeModeToggle', () {
    late _MockThemeCubit cubit;

    setUpAll(() => registerFallbackValue(AppThemeMode.system));

    setUp(() {
      cubit = _MockThemeCubit();
      when(() => cubit.setMode(any())).thenAnswer((_) async {});
    });

    testWidgets('reflects the current mode and switches it', (tester) async {
      whenListen(
        cubit,
        const Stream<AppThemeMode>.empty(),
        initialState: AppThemeMode.system,
      );
      await tester.pumpApp(
        BlocProvider<ThemeCubit>.value(
          value: cubit,
          child: const ThemeModeToggle(),
        ),
      );

      await tester.tap(find.text('Dark'));

      verify(() => cubit.setMode(AppThemeMode.dark)).called(1);
    });
  });
}
