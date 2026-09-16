import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/config/flavor/flavor.dart';
import 'package:novapay/config/flavor/flavor_config.dart';

void main() {
  const development = FlavorConfig(
    flavor: Flavor.development,
    hiveBoxName: 'novapay_development_box',
  );
  const production = FlavorConfig(
    flavor: Flavor.production,
    hiveBoxName: 'novapay_production_box',
  );

  test('only production reports itself as production', () {
    expect(development.isProduction, isFalse);
    expect(production.isProduction, isTrue);
  });

  test('each flavor owns a distinct box, so data cannot bleed across', () {
    expect(development.hiveBoxName, isNot(production.hiveBoxName));
  });

  test('compares by value', () {
    expect(
      development,
      const FlavorConfig(
        flavor: Flavor.development,
        hiveBoxName: 'novapay_development_box',
      ),
    );
    expect(development == production, isFalse);
    expect(development.hashCode, isNot(production.hashCode));
  });

  test('same flavor with a different box is still a different config', () {
    // A const instance is canonicalized, so the constructor never runs.
    // ignore: prefer_const_constructors
    final other = FlavorConfig(
      flavor: Flavor.development,
      hiveBoxName: 'some_other_box',
    );
    expect(development == other, isFalse);
  });

  test('describes itself for logs', () {
    expect(
      development.toString(),
      'FlavorConfig(development, novapay_development_box)',
    );
  });
}
