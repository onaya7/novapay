import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/profile/domain/entities/user_profile.dart';
import 'package:novapay/features/profile/domain/usecases/profile_usecases.dart';

part 'profile_cubit.freezed.dart';
part 'profile_state.dart';

/// App-wide, because the wallet greeting reads the same name the profile
/// screen edits.
@lazySingleton
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._load, this._save) : super(const ProfileState.loading());

  final LoadProfile _load;
  final SaveDisplayName _save;

  static const ConvertFailureToString _toMessage = ConvertFailureToString();

  Future<void> start() async {
    final result = await _load(const NoParams());
    emit(
      result.fold(
        (failure) => ProfileState.failure(_toMessage(failure)),
        ProfileState.ready,
      ),
    );
  }

  Future<void> rename(String name) async {
    final result = await _save(name);
    emit(
      result.fold(
        (failure) => ProfileState.failure(_toMessage(failure)),
        ProfileState.ready,
      ),
    );
  }
}
