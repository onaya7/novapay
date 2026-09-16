import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/profile/domain/entities/user_profile.dart';
import 'package:novapay/features/profile/domain/repositories/profile_repository.dart';
import 'package:novapay/features/profile/domain/usecases/profile_usecases.dart';

class _MockProfileRepository extends Mock implements ProfileRepository;

void main() {
  late _MockProfileRepository repository;

  setUp(() => repository = _MockProfileRepository());

  test('LoadProfile delegates', () async {
    const profile = UserProfile(displayName: 'Ada');
    when(repository.load).thenAnswer((_) async => const Right(profile));

    final result = await LoadProfile(repository)(const NoParams());

    expect(result, const Right<Failure, UserProfile>(profile));
    verify(repository.load).called(1);
  });

  test('LoadProfile passes a failure through untouched', () async {
    when(repository.load)
        .thenAnswer((_) async => const Left(Failure.noInternet()));

    final result = await LoadProfile(repository)(const NoParams());

    expect(result, const Left<Failure, UserProfile>(Failure.noInternet()));
  });

  test('SaveDisplayName hands the name through unchanged', () async {
    const profile = UserProfile(displayName: 'Ada');
    when(() => repository.saveDisplayName(any()))
        .thenAnswer((_) async => const Right(profile));

    final result = await SaveDisplayName(repository)('Ada');

    expect(result, const Right<Failure, UserProfile>(profile));
    verify(() => repository.saveDisplayName('Ada')).called(1);
  });
}
