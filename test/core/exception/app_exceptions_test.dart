import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/exception/app_exceptions.dart';

RequestOptions _options() => RequestOptions(path: '/wallet');

Response<dynamic> _response(dynamic data, int status) => Response<dynamic>(
  requestOptions: _options(),
  data: data,
  statusCode: status,
);

DioException _dio(
  DioExceptionType type, {
  Response<dynamic>? response,
  String? message,
}) => DioException(
  requestOptions: _options(),
  type: type,
  response: response,
  message: message,
);

void main() {
  group('AppException.fromDioError', () {
    test('every timeout type maps to a timeout', () {
      const timeouts = <DioExceptionType>[
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ];
      for (final type in timeouts) {
        expect(
          AppException.fromDioError(_dio(type)),
          const AppException.timeout(),
          reason: '$type should be a timeout',
        );
      }
    });

    test('a connection error is treated as offline', () {
      expect(
        AppException.fromDioError(_dio(DioExceptionType.connectionError)),
        const AppException.noInternet(),
      );
    });

    test('cancel, bad certificate and unknown carry the dio message', () {
      const others = <DioExceptionType>[
        DioExceptionType.badCertificate,
        DioExceptionType.cancel,
        DioExceptionType.unknown,
      ];
      for (final type in others) {
        expect(
          AppException.fromDioError(_dio(type, message: 'why')),
          const AppException.unknown('why'),
          reason: '$type should pass its message through',
        );
      }
    });

    test('a 401 is unauthorized, not a generic server error', () {
      final exception = AppException.fromDioError(
        _dio(
          DioExceptionType.badResponse,
          response: _response({'message': 'token expired'}, 401),
        ),
      );
      expect(exception, const AppException.unauthorized('token expired'));
    });

    test('other bad responses are server errors', () {
      final exception = AppException.fromDioError(
        _dio(
          DioExceptionType.badResponse,
          response: _response({'message': 'insufficient funds'}, 422),
        ),
      );
      expect(exception, const AppException.server('insufficient funds'));
    });
  });

  group('message extraction', () {
    test('reads a message out of a plain-text JSON body', () {
      final exception = AppException.fromDioError(
        _dio(
          DioExceptionType.badResponse,
          response: _response('{"message":"from a string body"}', 500),
        ),
      );
      expect(exception, const AppException.server('from a string body'));
    });

    test('falls back when the body is not JSON', () {
      final exception = AppException.fromDioError(
        _dio(
          DioExceptionType.badResponse,
          response: _response('<html>502</html>', 502),
        ),
      );
      expect(exception, const AppException.server('Server error'));
    });

    test('falls back on a null, empty or message-less body', () {
      for (final body in <dynamic>[null, '', '   ', <String, dynamic>{}]) {
        expect(
          AppException.fromDioError(
            _dio(DioExceptionType.badResponse, response: _response(body, 500)),
          ),
          const AppException.server('Server error'),
          reason: 'body $body should fall back',
        );
      }
    });

    test('ignores a blank or non-string message field', () {
      for (final body in <Map<String, dynamic>>[
        {'message': '  '},
        {'message': 42},
      ]) {
        expect(
          AppException.fromDioError(
            _dio(DioExceptionType.badResponse, response: _response(body, 500)),
          ),
          const AppException.server('Server error'),
        );
      }
    });

    test('falls back when there is no response at all', () {
      expect(
        AppException.fromDioError(_dio(DioExceptionType.badResponse)),
        const AppException.server('Server error'),
      );
    });
  });

  test('is an Exception', () {
    expect(const AppException.timeout(), isA<Exception>());
  });
}
