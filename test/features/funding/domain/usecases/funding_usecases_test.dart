import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/funding/domain/repositories/funding_repository.dart';
import 'package:novapay/features/funding/domain/usecases/funding_usecases.dart';

class _MockFundingRepository extends Mock implements FundingRepository;

void main() {
  late _MockFundingRepository repository;

  setUpAll(() => registerFallbackValue(Money.zero));

  setUp(() => repository = _MockFundingRepository());

  test('LoadWalletBalance delegates', () async {
    when(repository.balance)
        .thenAnswer((_) async => const Right(Money.fromKobo(100)));

    final result = await LoadWalletBalance(repository)(const NoParams());

    expect(result, const Right<Failure, Money>(Money.fromKobo(100)));
    verify(repository.balance).called(1);
  });

  test('LoadWalletBalance passes a failure through untouched', () async {
    when(repository.balance)
        .thenAnswer((_) async => const Left(Failure.noInternet()));

    final result = await LoadWalletBalance(repository)(const NoParams());

    expect(result, const Left<Failure, Money>(Failure.noInternet()));
  });

  test('AddMoney hands the amount through unchanged', () async {
    when(() => repository.addMoney(any()))
        .thenAnswer((_) async => const Right(unit));

    final result = await AddMoney(repository)(const Money.fromKobo(500000));

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.addMoney(const Money.fromKobo(500000))).called(1);
  });
}
