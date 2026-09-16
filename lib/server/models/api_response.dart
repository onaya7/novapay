import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';

enum ApiStatus { success, error }

/// The single shape every endpoint returns, so callers never have to guess
/// what came back.
///
/// A business refusal is an error *response* with a code, the way a real API
/// answers a 422. Only a transport failure throws.
@freezed
abstract class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required ApiStatus status,
    required int code,
    required String message,
    T? data,
  }) = _ApiResponse<T>;

  const ApiResponse._();

  factory ApiResponse.ok(T data, {int code = 200, String message = 'OK'}) =>
      ApiResponse<T>(
        status: ApiStatus.success,
        code: code,
        message: message,
        data: data,
      );

  factory ApiResponse.created(T data, {String message = 'Created'}) =>
      ApiResponse<T>.ok(data, code: 201, message: message);

  factory ApiResponse.failure({required int code, required String message}) =>
      ApiResponse<T>(status: ApiStatus.error, code: code, message: message);

  bool get isSuccess => status == ApiStatus.success;

  bool get isError => status == ApiStatus.error;

  /// The payload of a successful response. Throws when read off an error, so a
  /// caller that forgot to check [isSuccess] fails loudly rather than silently.
  T get requireData {
    final value = data;
    if (value == null) {
      throw StateError('no data on a $code response: $message');
    }
    return value;
  }
}
