import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  const factory Failure.serverError(String message) = ServerFailure;
  const factory Failure.noInternet() = NoInternetFailure;
  const factory Failure.unauthorized(String message) = UnauthorizedFailure;
  const factory Failure.unknown() = UnknownFailure;
  const factory Failure.app(String? message) = AppFailure;
}

class ConvertFailureToString {
  const ConvertFailureToString();

  String call(Failure failure) {
    return switch (failure) {
      ServerFailure(:final message) => message,
      NoInternetFailure() =>
        'Please check your internet connection and try again',
      UnauthorizedFailure(:final message) => message,
      UnknownFailure() => 'An unknown error occurred',
      AppFailure(:final message) => message ?? 'An unknown error occurred',
    };
  }
}
