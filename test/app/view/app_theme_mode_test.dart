import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/presentation/cubit/theme_cubit.dart';
import 'package:novapay/app/view/app.dart';
import 'package:novapay/l10n/gen/app_localizations_en.dart';

void main() {
  test('each mode maps to its Flutter ThemeMode and its label', () {
    final l10n = AppLocalizationsEn();

    expect(AppThemeMode.system.asThemeMode, ThemeMode.system);
    expect(AppThemeMode.light.asThemeMode, ThemeMode.light);
    expect(AppThemeMode.dark.asThemeMode, ThemeMode.dark);

    expect(AppThemeMode.system.label(l10n), 'System');
    expect(AppThemeMode.light.label(l10n), 'Light');
    expect(AppThemeMode.dark.label(l10n), 'Dark');
  });
}
