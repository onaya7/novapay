import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:novapay/app/presentation/cubit/theme_cubit.dart';
import 'package:novapay/core/constants/storage_keys.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late LocalDataStorage db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_theme');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('theme_test');
    db = LocalDataStorageImpl(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('with nothing saved, it follows the system', () {
    final cubit = ThemeCubit(db);

    expect(cubit.state, AppThemeMode.system);
  });

  test('an unreadable value also falls back to the system', () async {
    await box.put(StorageKeys.themeMode, 'sepia');

    final cubit = ThemeCubit(db);

    expect(cubit.state, AppThemeMode.system);
  });

  test('restores a previously saved mode in the constructor', () async {
    await box.put(StorageKeys.themeMode, 'dark');

    final cubit = ThemeCubit(db);

    expect(cubit.state, AppThemeMode.dark);
  });

  test('setMode emits and persists', () async {
    final cubit = ThemeCubit(db);

    await cubit.setMode(AppThemeMode.dark);

    expect(cubit.state, AppThemeMode.dark);
    expect(db.read<String>(StorageKeys.themeMode), 'dark');
  });

  test('setting the same mode again is a no-op', () async {
    final cubit = ThemeCubit(db);
    await cubit.setMode(AppThemeMode.light);
    await box.delete(StorageKeys.themeMode);

    await cubit.setMode(AppThemeMode.light);

    expect(db.read<String>(StorageKeys.themeMode), isNull);
  });
}
