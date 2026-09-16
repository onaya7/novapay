import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/network_info/network_info.dart';

class _MockInternetConnection extends Mock implements InternetConnection;

void main() {
  late _MockInternetConnection checker;
  late NetworkInfo networkInfo;

  setUp(() {
    checker = _MockInternetConnection();
    networkInfo = NetworkInfoImpl(checker);
  });

  group('isConnected', () {
    test('reports a reachable network', () async {
      when(() => checker.hasInternetAccess).thenAnswer((_) async => true);
      expect(await networkInfo.isConnected, isTrue);
    });

    test('reports an unreachable one', () async {
      when(() => checker.hasInternetAccess).thenAnswer((_) async => false);
      expect(await networkInfo.isConnected, isFalse);
    });

    test('asks the checker, not the interface state', () async {
      when(() => checker.hasInternetAccess).thenAnswer((_) async => true);
      await networkInfo.isConnected;
      verify(() => checker.hasInternetAccess).called(1);
    });
  });

  group('onConnectivityChanged', () {
    test('maps each status to a boolean', () {
      when(() => checker.onStatusChange).thenAnswer(
        (_) => Stream<InternetStatus>.fromIterable(const [
          InternetStatus.connected,
          InternetStatus.disconnected,
          InternetStatus.connected,
        ]),
      );
      expect(
        networkInfo.onConnectivityChanged,
        emitsInOrder(<Object>[true, false, true, emitsDone]),
      );
    });

    test('an empty stream yields nothing', () {
      when(() => checker.onStatusChange)
          .thenAnswer((_) => const Stream<InternetStatus>.empty());
      expect(networkInfo.onConnectivityChanged, emitsDone);
    });
  });
}
