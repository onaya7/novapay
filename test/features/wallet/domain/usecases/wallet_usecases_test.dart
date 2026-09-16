import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:novapay/features/wallet/domain/usecases/load_wallet.dart';
import 'package:novapay/features/wallet/domain/usecases/watch_wallet.dart';

class _MockWalletRepository extends Mock implements WalletRepository;

const _snapshot = WalletSnapshot(
  confirmedKobo: 1000,
  pendingKobo: 0,
  activity: [],
);

void main() {
  late _MockWalletRepository repository;

  setUp(() => repository = _MockWalletRepository());

  test('LoadWallet hands back whatever the repository resolved', () async {
    when(repository.load).thenAnswer((_) async => const Right(_snapshot));

    final result = await LoadWallet(repository)(const NoParams());

    expect(result, const Right<Failure, WalletSnapshot>(_snapshot));
    verify(repository.load).called(1);
  });

  test('LoadWallet passes a failure through untouched', () async {
    when(repository.load)
        .thenAnswer((_) async => const Left(Failure.noInternet()));

    final result = await LoadWallet(repository)(const NoParams());

    expect(result, const Left<Failure, WalletSnapshot>(Failure.noInternet()));
  });

  test('WatchWallet forwards the repository stream', () {
    when(repository.watch).thenAnswer((_) => Stream.value(_snapshot));

    expect(
      WatchWallet(repository)(const NoParams()),
      emitsInOrder([_snapshot, emitsDone]),
    );
  });
}
