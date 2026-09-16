import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:novapay/utils/either_safe_runner.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late LocalDataStorage db;
  late ProfileRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_profile');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('profile_test');
    db = LocalDataStorageImpl(box);
    repository = ProfileRepositoryImpl(db, const EitherSafeRunner());
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('load falls back to an empty name before anything is saved', () async {
    final result = await repository.load();

    expect(
      result.getOrElse(() => throw StateError('expected a profile')).hasName,
      isFalse,
    );
  });

  test('saveDisplayName trims and persists, then load reads it back', () async {
    final saved = await repository.saveDisplayName('  Ada Lovelace  ');

    expect(
      saved.getOrElse(() => throw StateError('expected a profile')).displayName,
      'Ada Lovelace',
    );

    final loaded = await repository.load();

    expect(
      loaded
          .getOrElse(() => throw StateError('expected a profile'))
          .displayName,
      'Ada Lovelace',
    );
  });
}
