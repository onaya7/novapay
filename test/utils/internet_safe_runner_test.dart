import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/exception/app_exceptions.dart';
import 'package:novapay/core/network_info/network_info.dart';
import 'package:novapay/utils/internet_safe_runner.dart';

class _MockNetworkInfo extends Mock implements NetworkInfo;

void main() {
  late _MockNetworkInfo networkInfo;
  late InternetSafeRunner runner;

  setUp(() {
    networkInfo = _MockNetworkInfo();
    runner = InternetSafeRunner(networkInfo);
  });

  void givenConnected({required bool connected}) {
    when(() => networkInfo.isConnected).thenAnswer((_) async => connected);
  }

  test('runs the callback when there is a connection', () async {
    givenConnected(connected: true);
    expect(await runner<int>(safeCallback: () async => 7), 7);
  });

  test('throws noInternet when offline', () async {
    givenConnected(connected: false);
    expect(
      () => runner<int>(safeCallback: () async => 7),
      throwsA(const AppException.noInternet()),
    );
  });

  test('does not touch the network when offline', () async {
    givenConnected(connected: false);
    var called = false;
    await expectLater(
      runner<int>(
        safeCallback: () async {
          called = true;
          return 7;
        },
      ),
      throwsA(const AppException.noInternet()),
    );
    expect(called, isFalse, reason: 'the request must not be attempted');
  });

  test('a callback failure propagates rather than being swallowed', () async {
    givenConnected(connected: true);
    expect(
      () => runner<int>(
        safeCallback: () async => throw const AppException.server('boom'),
      ),
      throwsA(const AppException.server('boom')),
    );
  });
}
