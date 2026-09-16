import 'package:novapay/app/app.dart';
import 'package:novapay/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
