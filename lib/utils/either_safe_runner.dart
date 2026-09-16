import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/exception/app_exceptions.dart';
import 'package:novapay/utils/logger.dart';

class EitherSafeRunner {
  const EitherSafeRunner();

  Future<Either<Failure, T>> call<T>({
    required Future<T> Function() safeCallback,
  }) async {
    try {
      return Right(await safeCallback());
    } on AppException catch (e) {
      return Left(_mapException(e));
    } on DioException catch (e, st) {
      logger.e('DioException', error: e, stackTrace: st);
      return Left(_mapException(AppException.fromDioError(e)));
    } on Exception catch (e, st) {
      logger.e('EitherSafeRunner', error: e, stackTrace: st);
      return const Left(Failure.unknown());
    }
  }

  Failure _mapException(AppException e) {
    return switch (e) {
      ServerException(:final message) => Failure.serverError(message),
      NoInternetException() => const Failure.noInternet(),
      UnauthorizedException(:final message) => Failure.unauthorized(message),
      TimeoutException() => const Failure.serverError(
        kDebugMode ? 'Request timed out' : 'Server error',
      ),
      UnknownException(:final message) => Failure.app(message),
    };
  }
}
