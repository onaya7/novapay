import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:novapay/config/flavor/flavor_config.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  InternetConnection get internetConnection => InternetConnection();

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  /// Opened during bootstrap, so resolving this never does disk work.
  @lazySingleton
  Box<dynamic> appBox(FlavorConfig config) =>
      Hive.box<dynamic>(config.hiveBoxName);
}
