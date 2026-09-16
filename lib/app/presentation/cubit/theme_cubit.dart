import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/constants/storage_keys.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';

enum AppThemeMode { system, light, dark }

/// The chosen theme, restored **in the constructor** rather than after a first
/// frame, so the app never flashes the wrong one on launch.
@lazySingleton
class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit(this._storage) : super(_restore(_storage));

  final LocalDataStorage _storage;

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _storage.write<String>(StorageKeys.themeMode, mode.name);
  }

  /// An unreadable or absent value falls back to following the system, which
  /// is the only choice that is never wrong.
  static AppThemeMode _restore(LocalDataStorage storage) {
    final stored = storage.read<String>(StorageKeys.themeMode);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => AppThemeMode.system,
    );
  }
}
