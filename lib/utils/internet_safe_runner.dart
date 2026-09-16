import 'package:novapay/core/exception/app_exceptions.dart';
import 'package:novapay/core/network_info/network_info.dart';

class InternetSafeRunner {
  const InternetSafeRunner(this.networkInfo);

  final NetworkInfo networkInfo;

  Future<T> call<T>({required Future<T> Function() safeCallback}) async {
    if (await networkInfo.isConnected) {
      return await safeCallback();
    }
    throw const AppException.noInternet();
  }
}
