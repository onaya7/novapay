import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/presentation/cubit/locale_cubit.dart';
import 'package:novapay/app/view/app.dart';

void main() {
  test('each locale maps to its Flutter Locale and its label', () {
    expect(AppLocale.system.asLocale, isNull);
    expect(AppLocale.en.asLocale, const Locale('en'));
    expect(AppLocale.ha.asLocale, const Locale('ha'));

    expect(AppLocale.system.label, 'System');
    expect(AppLocale.en.label, 'English');
    expect(AppLocale.ha.label, 'Hausa');
  });
}
