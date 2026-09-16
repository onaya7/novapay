import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/injections/injection.config.dart';

final GetIt sl = GetIt.instance;

@InjectableInit(asExtension: false)
Future<void> configureDependencies() async => init(sl);
