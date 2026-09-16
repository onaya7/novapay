import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:novapay/config/flavor/flavor.dart';
import 'package:novapay/config/flavor/flavor_config.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/core/local_data/secure_local_data_storage.dart';
import 'package:novapay/core/network_info/network_info.dart';
import 'package:novapay/core/sync/sync_service.dart';
import 'package:novapay/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:novapay/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:novapay/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:novapay/server/novapay_api.dart';
import 'package:novapay/utils/either_safe_runner.dart';

const _boxName = 'novapay_test_box';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_di');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(_boxName);
    sl.registerSingleton<FlavorConfig>(
      const FlavorConfig(flavor: Flavor.development, hiveBoxName: _boxName),
    );
    await configureDependencies();
  });

  tearDown(() async {
    await sl.reset();
    await Hive.deleteBoxFromDisk(_boxName);
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('resolves connectivity', () {
    expect(sl<InternetConnection>(), isA<InternetConnection>());
    expect(sl<NetworkInfo>(), isA<NetworkInfoImpl>());
  });

  test('resolves the wallet graph down to its error translator', () {
    expect(sl<EitherSafeRunner>(), isA<EitherSafeRunner>());
    expect(sl<NovaPayApi>(), isA<NovaPayApiImpl>());
    expect(sl<SyncService>(), isA<SyncServiceImpl>());
    expect(sl<WalletRepository>(), isA<WalletRepositoryImpl>());
    expect(sl<WalletCubit>(), isA<WalletCubit>());
  });

  test('resolves both storages', () {
    expect(sl<FlutterSecureStorage>(), isA<FlutterSecureStorage>());
    expect(sl<SecureLocalDataStorage>(), isA<SecureLocalDataStorageImpl>());
    expect(sl<LocalDataStorage>(), isA<LocalDataStorageImpl>());
  });

  test('the box comes from the flavor, so builds cannot share data', () {
    expect(sl<Box<dynamic>>().name, _boxName);
  });

  test('lazy singletons hand back the same instance', () {
    expect(identical(sl<NetworkInfo>(), sl<NetworkInfo>()), isTrue);
    expect(identical(sl<LocalDataStorage>(), sl<LocalDataStorage>()), isTrue);
  });

  test('the resolved storage actually round-trips through the box', () async {
    final storage = sl<LocalDataStorage>();
    await storage.write<String>('k', 'v');
    expect(storage.read<String>('k'), 'v');
    await storage.delete('k');
    expect(storage.read<String>('k'), isNull);
  });
}
