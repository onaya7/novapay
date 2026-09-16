import 'package:novapay/app/app.dart';
import 'package:novapay/bootstrap.dart';
import 'package:novapay/config/flavor/flavor.dart';
import 'package:novapay/config/flavor/flavor_config.dart';

Future<void> main() async {
  await bootstrap(
    const FlavorConfig(
      flavor: Flavor.production,
      hiveBoxName: 'novapay_production_box',
    ),
    () => const App(),
  );
}
