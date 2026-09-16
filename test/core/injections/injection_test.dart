import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/core/network_info/network_info.dart';

void main() {
  tearDown(sl.reset);

  test('the container resolves connectivity', () async {
    await configureDependencies();
    expect(sl<InternetConnection>(), isA<InternetConnection>());
  });

  test('NetworkInfo resolves to its implementation', () async {
    await configureDependencies();
    expect(sl<NetworkInfo>(), isA<NetworkInfoImpl>());
  });

  test('lazy singletons hand back the same instance', () async {
    await configureDependencies();
    expect(identical(sl<NetworkInfo>(), sl<NetworkInfo>()), isTrue);
  });
}
