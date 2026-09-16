import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/domain/usecases/load_wallet.dart';
import 'package:novapay/features/wallet/domain/usecases/watch_wallet.dart';
import 'package:novapay/features/wallet/presentation/cubit/wallet_cubit.dart';

class _MockLoadWallet extends Mock implements LoadWallet;

class _MockWatchWallet extends Mock implements WatchWallet;

const _first = WalletSnapshot(
  confirmedKobo: 24800000,
  pendingKobo: 0,
  activity: [],
);

const _second = WalletSnapshot(
  confirmedKobo: 24800000,
  pendingKobo: 500000,
  activity: [],
);

void main() {
  late _MockLoadWallet load;
  late _MockWatchWallet watch;
  late StreamController<WalletSnapshot> updates;

  void loadResolves(Either<Failure, WalletSnapshot> result) {
    when(() => load(const NoParams())).thenAnswer((_) async => result);
  }

  setUp(() {
    load = _MockLoadWallet();
    watch = _MockWatchWallet();
    updates = StreamController<WalletSnapshot>.broadcast();
    when(() => watch(const NoParams())).thenAnswer((_) => updates.stream);
    loadResolves(const Right(_first));
  });

  tearDown(() => updates.close());

  test('opens on loading, so the first frame is never a blank screen', () {
    expect(WalletCubit(load, watch).state, const WalletState.loading());
  });

  test('start loads once and shows the result', () async {
    final cubit = WalletCubit(load, watch);

    await cubit.start();

    expect(cubit.state, const WalletState.ready(_first));
    verify(() => load(const NoParams())).called(1);
    await cubit.close();
  });

  test('a queued send reaches the screen without a reload', () async {
    final cubit = WalletCubit(load, watch);
    await cubit.start();

    updates.add(_second);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, const WalletState.ready(_second));
    verify(() => load(const NoParams())).called(1);
    await cubit.close();
  });

  test('start twice does not stack a second subscription', () async {
    final cubit = WalletCubit(load, watch);

    await cubit.start();
    await cubit.start();

    expect(updates.hasListener, isTrue);
    verify(() => load(const NoParams())).called(2);
    verify(() => watch(const NoParams())).called(1);
    await cubit.close();
  });

  test('a failure is shown as copy, never as a raw failure', () async {
    loadResolves(const Left(Failure.noInternet()));
    final cubit = WalletCubit(load, watch);

    await cubit.start();

    expect(
      cubit.state,
      const WalletState.failure(
        'Please check your internet connection and try again',
      ),
    );
    await cubit.close();
  });

  test('refresh replaces a failure with data', () async {
    loadResolves(const Left(Failure.noInternet()));
    final cubit = WalletCubit(load, watch);
    await cubit.start();

    loadResolves(const Right(_first));
    await cubit.refresh();

    expect(cubit.state, const WalletState.ready(_first));
    await cubit.close();
  });

  test('closing releases the queue subscription', () async {
    final cubit = WalletCubit(load, watch);
    await cubit.start();
    expect(updates.hasListener, isTrue);

    await cubit.close();

    expect(updates.hasListener, isFalse);
    expect(cubit.isClosed, isTrue);
  });
}
