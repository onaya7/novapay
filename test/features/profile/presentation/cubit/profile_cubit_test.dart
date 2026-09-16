import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/profile/domain/entities/user_profile.dart';
import 'package:novapay/features/profile/domain/usecases/profile_usecases.dart';
import 'package:novapay/features/profile/presentation/cubit/profile_cubit.dart';

class _MockLoadProfile extends Mock implements LoadProfile;

class _MockSaveDisplayName extends Mock implements SaveDisplayName;

void main() {
  late _MockLoadProfile load;
  late _MockSaveDisplayName save;

  setUp(() {
    load = _MockLoadProfile();
    save = _MockSaveDisplayName();
  });

  ProfileCubit build() => ProfileCubit(load, save);

  blocTest<ProfileCubit, ProfileState>(
    'start loads the profile',
    setUp: () {
      when(
        () => load(const NoParams()),
      ).thenAnswer((_) async => const Right(UserProfile(displayName: 'Ada')));
    },
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [const ProfileState.ready(UserProfile(displayName: 'Ada'))],
  );

  blocTest<ProfileCubit, ProfileState>(
    'start surfaces a failure',
    setUp: () {
      when(() => load(const NoParams()))
          .thenAnswer((_) async => const Left(Failure.noInternet()));
    },
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [
      const ProfileState.failure(
        'Please check your internet connection and try again',
      ),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'rename saves and reflects the new name',
    setUp: () {
      when(
        () => save('Ada'),
      ).thenAnswer((_) async => const Right(UserProfile(displayName: 'Ada')));
    },
    build: build,
    act: (cubit) => cubit.rename('Ada'),
    expect: () => [const ProfileState.ready(UserProfile(displayName: 'Ada'))],
  );

  blocTest<ProfileCubit, ProfileState>(
    'rename surfaces a failure',
    setUp: () {
      when(() => save('Ada'))
          .thenAnswer((_) async => const Left(Failure.noInternet()));
    },
    build: build,
    act: (cubit) => cubit.rename('Ada'),
    expect: () => [
      const ProfileState.failure(
        'Please check your internet connection and try again',
      ),
    ],
  );
}
