import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/presentation/cubit/locale_cubit.dart';
import 'package:novapay/app/view/app.dart';
import 'package:novapay/l10n/gen/app_localizations_en.dart';

void main() {
  test('each locale maps to its Flutter Locale and its label', () {
    final l10n = AppLocalizationsEn();

    expect(AppLocale.system.asLocale, isNull);
    expect(AppLocale.en.asLocale, const Locale('en'));
    expect(AppLocale.es.asLocale, const Locale('es'));
    expect(AppLocale.fr.asLocale, const Locale('fr'));

    // Language names stay in their own spelling, regardless of l10n.
    expect(AppLocale.system.label(l10n), 'System');
    expect(AppLocale.en.label(l10n), 'English');
    expect(AppLocale.es.label(l10n), 'Español');
    expect(AppLocale.fr.label(l10n), 'Français');
  });
}
