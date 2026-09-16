import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/exception/app_exceptions.dart';
import 'package:novapay/utils/either_safe_runner.dart';

void main() {
  const runner = EitherSafeRunner();

  test('the constructor runs, not just its canonicalized const form', () {
    // Every call site elsewhere is const, so the constructor is otherwise
    // canonicalized away and never actually executes.
    // ignore: prefer_const_constructors
    expect(EitherSafeRunner(), isA<EitherSafeRunner>());
  });

  Future<Failure> failureFrom(Future<int> Function() callback) async {
    final result = await runner<int>(safeCallback: callback);
    return result.fold<Failure>(
      (failure) => failure,
      (_) => fail('expected a Left'),
    );
  }

  test('a successful call comes back as Right', () async {
    final result = await runner<int>(safeCallback: () async => 7);
    expect(result, const Right<Failure, int>(7));
  });

  group('AppException maps to its Failure', () {
    test('server', () async {
      expect(
        await failureFrom(() async => throw const AppException.server('boom')),
        const Failure.serverError('boom'),
      );
    });

    test('no internet', () async {
      expect(
        await failureFrom(() async => throw const AppException.noInternet()),
        const Failure.noInternet(),
      );
    });

    test('unauthorized', () async {
      expect(
        await failureFrom(
          () async => throw const AppException.unauthorized('expired'),
        ),
        const Failure.unauthorized('expired'),
      );
    });

    test('timeout becomes a server error', () async {
      expect(
        await failureFrom(() async => throw const AppException.timeout()),
        const Failure.serverError('Request timed out'),
      );
    });

    test('unknown becomes an app failure', () async {
      expect(
        await failureFrom(() async => throw const AppException.unknown('odd')),
        const Failure.app('odd'),
      );
    });
  });

  test('a raw DioException is translated, not swallowed', () async {
    expect(
      await failureFrom(
        () async => throw DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      ),
      const Failure.noInternet(),
    );
  });

  test('any other exception degrades to unknown', () async {
    expect(
      await failureFrom(() async => throw const FormatException('bad')),
      const Failure.unknown(),
    );
  });

  test('an Error escapes, because it is a bug and not a failure', () async {
    await expectLater(
      runner<int>(safeCallback: () async => throw StateError('bug')),
      throwsStateError,
    );
  });
}
