import 'package:novapay/app/app.dart';
import 'package:novapay/bootstrap.dart';
import 'package:novapay/config/flavor/flavor.dart';
import 'package:novapay/config/flavor/flavor_config.dart';

Future<void> main() async {
  await bootstrap(
    const FlavorConfig(
      flavor: Flavor.development,
      hiveBoxName: 'novapay_development_box',
    ),
    () => const App(),
  );
}
