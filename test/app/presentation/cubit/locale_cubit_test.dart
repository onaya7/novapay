import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:novapay/app/presentation/cubit/locale_cubit.dart';
import 'package:novapay/core/constants/storage_keys.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late LocalDataStorage db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_locale');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('locale_test');
    db = LocalDataStorageImpl(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('with nothing saved, it follows the system', () {
    final cubit = LocaleCubit(db);

    expect(cubit.state, AppLocale.system);
  });

  test('an unreadable value also falls back to the system', () async {
    await box.put(StorageKeys.locale, 'xx');

    final cubit = LocaleCubit(db);

    expect(cubit.state, AppLocale.system);
  });

  test('restores a previously saved locale in the constructor', () async {
    await box.put(StorageKeys.locale, 'fr');

    final cubit = LocaleCubit(db);

    expect(cubit.state, AppLocale.fr);
  });

  test('setLocale emits and persists', () async {
    final cubit = LocaleCubit(db);

    await cubit.setLocale(AppLocale.fr);

    expect(cubit.state, AppLocale.fr);
    expect(db.read<String>(StorageKeys.locale), 'fr');
  });

  test('setting the same locale again is a no-op', () async {
    final cubit = LocaleCubit(db);
    await cubit.setLocale(AppLocale.en);
    await box.delete(StorageKeys.locale);

    await cubit.setLocale(AppLocale.en);

    expect(db.read<String>(StorageKeys.locale), isNull);
  });
}
