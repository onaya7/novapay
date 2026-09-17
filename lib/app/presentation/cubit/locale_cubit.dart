import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/constants/storage_keys.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';

enum AppLocale { system, en, es, fr }

/// The chosen language, restored **in the constructor** rather than after a
/// first frame, so the app never flashes the wrong one on launch.
@lazySingleton
class LocaleCubit extends Cubit<AppLocale> {
  LocaleCubit(this._storage) : super(_restore(_storage));

  final LocalDataStorage _storage;

  Future<void> setLocale(AppLocale locale) async {
    if (locale == state) return;
    emit(locale);
    await _storage.write<String>(StorageKeys.locale, locale.name);
  }

  /// An unreadable or absent value falls back to following the system, which
  /// is the only choice that is never wrong.
  static AppLocale _restore(LocalDataStorage storage) {
    final stored = storage.read<String>(StorageKeys.locale);
    return AppLocale.values.firstWhere(
      (locale) => locale.name == stored,
      orElse: () => AppLocale.system,
    );
  }
}
