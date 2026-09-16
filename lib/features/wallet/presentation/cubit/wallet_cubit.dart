import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/domain/usecases/load_wallet.dart';
import 'package:novapay/features/wallet/domain/usecases/watch_wallet.dart';

part 'wallet_cubit.freezed.dart';
part 'wallet_state.dart';

@injectable
class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._load, this._watch) : super(const WalletState.loading());

  final LoadWallet _load;
  final WatchWallet _watch;

  static const ConvertFailureToString _toMessage = ConvertFailureToString();

  StreamSubscription<WalletSnapshot>? _subscription;

  /// Loads once, then follows the queue so a queued send appears immediately.
  Future<void> start() async {
    await refresh();
    _subscription ??= _watch(const NoParams()).listen(_onSnapshot);
  }

  Future<void> refresh() async {
    final result = await _load(const NoParams());
    emit(
      result.fold(
        (failure) => WalletState.failure(_toMessage(failure)),
        WalletState.ready,
      ),
    );
  }

  void _onSnapshot(WalletSnapshot snapshot) {
    emit(WalletState.ready(snapshot));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
