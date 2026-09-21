import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/app/presentation/cubit/splash_cubit.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/domain/usecases/load_wallet.dart';

class _MockLoadWallet extends Mock implements LoadWallet;

const _snapshot = WalletSnapshot(
  confirmedKobo: 24800000,
  pendingKobo: 0,
  activity: [],
);

/// A load that never answers, for the two cases about giving up on one.
Future<Either<Failure, WalletSnapshot>> _neverAnswers(Invocation _) =>
    Completer<Either<Failure, WalletSnapshot>>().future;

void main() {
  late _MockLoadWallet load;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    load = _MockLoadWallet();
    when(() => load(any())).thenAnswer((_) async => const Right(_snapshot));
  });

  blocTest<SplashCubit, SplashStatus>(
    'warms the wallet, then reports ready',
    build: () => SplashCubit(load),
    act: (cubit) => cubit.start(),
    wait: SplashCubit.minimumHold,
    expect: () => [SplashStatus.ready],
    verify: (_) => verify(() => load(any())).called(1),
  );

  blocTest<SplashCubit, SplashStatus>(
    'a refused warm-up still reaches the wallet',
    build: () {
      when(() => load(any()))
          .thenAnswer((_) async => const Left(Failure.serverError('offline')));
      return SplashCubit(load);
    },
    act: (cubit) => cubit.start(),
    wait: SplashCubit.minimumHold,
    expect: () => [SplashStatus.ready],
  );

  blocTest<SplashCubit, SplashStatus>(
    'a throwing warm-up is swallowed rather than stranding the screen',
    build: () {
      when(() => load(any())).thenThrow(Exception('boom'));
      return SplashCubit(load);
    },
    act: (cubit) => cubit.start(),
    wait: SplashCubit.minimumHold,
    expect: () => [SplashStatus.ready],
  );

  test('holds for the entrance even when the wallet answers instantly', () {
    fakeAsync((async) {
      final cubit = SplashCubit(load);
      unawaited(cubit.start());

      async.elapse(SplashCubit.minimumHold ~/ 2);
      expect(cubit.state, SplashStatus.preparing);

      async.elapse(SplashCubit.minimumHold);
      expect(cubit.state, SplashStatus.ready);

      unawaited(cubit.close());
      async.flushMicrotasks();
    });
  });

  test('a warm-up that never answers gives up at the budget', () {
    fakeAsync((async) {
      when(() => load(any())).thenAnswer(_neverAnswers);
      final cubit = SplashCubit(load);
      unawaited(cubit.start());

      async.elapse(SplashCubit.budget - const Duration(milliseconds: 1));
      expect(cubit.state, SplashStatus.preparing);

      async.elapse(const Duration(milliseconds: 1));
      expect(cubit.state, SplashStatus.ready);

      unawaited(cubit.close());
      async.flushMicrotasks();
    });
  });

  test('a close before the warm-up finishes emits nothing', () {
    fakeAsync((async) {
      when(() => load(any())).thenAnswer(_neverAnswers);
      final cubit = SplashCubit(load);
      unawaited(cubit.start());
      unawaited(cubit.close());
      async.elapse(SplashCubit.budget * 2);

      expect(cubit.state, SplashStatus.preparing);
    });
  });
}
