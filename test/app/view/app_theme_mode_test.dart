import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/presentation/cubit/theme_cubit.dart';
import 'package:novapay/app/view/app.dart';

void main() {
  test('each mode maps to its Flutter ThemeMode and its label', () {
    expect(AppThemeMode.system.asThemeMode, ThemeMode.system);
    expect(AppThemeMode.light.asThemeMode, ThemeMode.light);
    expect(AppThemeMode.dark.asThemeMode, ThemeMode.dark);

    expect(AppThemeMode.system.label, 'System');
    expect(AppThemeMode.light.label, 'Light');
    expect(AppThemeMode.dark.label, 'Dark');
  });
}
