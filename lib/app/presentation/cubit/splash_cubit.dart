import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/wallet/domain/usecases/load_wallet.dart';

enum SplashStatus { preparing, ready }

/// Holds the brand screen while the wallet warms up, so the first real frame
/// is a populated wallet rather than a skeleton.
@injectable
class SplashCubit extends Cubit<SplashStatus> {
  SplashCubit(this._load) : super(SplashStatus.preparing);

  final LoadWallet _load;

  /// Matches the view's entrance, so a warm cache cannot cut the animation off
  /// part-way through.
  static const Duration minimumHold = Duration(milliseconds: 250);

  /// A cold start must reach the wallet even if the warm-up never answers.
  static const Duration budget = Duration(seconds: 3);

  Future<void> start() async {
    await Future.wait<void>([_warm(), Future<void>.delayed(minimumHold)]);
    if (!isClosed) emit(SplashStatus.ready);
  }

  Future<void> _warm() async {
    try {
      await _load(const NoParams()).timeout(budget);
    } on Object {
      return;
    }
  }
}
