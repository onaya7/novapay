import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/error/failure.dart';

void main() {
  const convert = ConvertFailureToString();

  group('ConvertFailureToString', () {
    test('server error passes its message through', () {
      expect(convert(const Failure.serverError('boom')), 'boom');
    });

    test('no internet reads as something the user can act on', () {
      expect(
        convert(const Failure.noInternet()),
        'Please check your internet connection and try again',
      );
    });

    test('unauthorized passes its message through', () {
      expect(
        convert(const Failure.unauthorized('session expired')),
        'session expired',
      );
    });

    test('unknown falls back', () {
      expect(convert(const Failure.unknown()), 'An unknown error occurred');
    });

    test('app failure falls back only when the message is null', () {
      expect(convert(const Failure.app('bad input')), 'bad input');
      expect(convert(const Failure.app(null)), 'An unknown error occurred');
    });
  });

  test('failures compare by value', () {
    expect(const Failure.serverError('x'), const Failure.serverError('x'));
    expect(const Failure.noInternet(), const Failure.noInternet());
    expect(
      const Failure.serverError('x') == const Failure.serverError('y'),
      isFalse,
    );
  });
}
