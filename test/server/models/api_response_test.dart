import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/server/models/api_response.dart';

void main() {
  test('ok is a 200 carrying its payload', () {
    final response = ApiResponse<int>.ok(7);
    expect(response.status, ApiStatus.success);
    expect(response.code, 200);
    expect(response.message, 'OK');
    expect(response.isSuccess, isTrue);
    expect(response.isError, isFalse);
    expect(response.requireData, 7);
  });

  test('created is a 201', () {
    final response = ApiResponse<String>.created('made');
    expect(response.code, 201);
    expect(response.message, 'Created');
    expect(response.requireData, 'made');
  });

  test('ok takes a custom code and message', () {
    final response = ApiResponse<int>.ok(1, code: 202, message: 'Accepted');
    expect(response.code, 202);
    expect(response.message, 'Accepted');
  });

  test('failure carries a code and no payload', () {
    final response = ApiResponse<int>.failure(
      code: 402,
      message: 'Not enough in your wallet',
    );
    expect(response.status, ApiStatus.error);
    expect(response.isError, isTrue);
    expect(response.isSuccess, isFalse);
    expect(response.data, isNull);
    expect(response.message, 'Not enough in your wallet');
  });

  test('reading data off an error throws rather than returning null', () {
    // A caller that forgot to check isSuccess should fail loudly.
    final response = ApiResponse<int>.failure(code: 404, message: 'gone');
    expect(() => response.requireData, throwsStateError);
  });

  test('every endpoint answers the same four fields', () {
    const response = ApiResponse<int>(
      status: ApiStatus.success,
      code: 200,
      message: 'OK',
      data: 1,
    );
    expect(response.status, ApiStatus.success);
    expect(response.code, 200);
    expect(response.message, 'OK');
    expect(response.data, 1);
  });

  test('compares by value and copies', () {
    final response = ApiResponse<int>.ok(1);
    expect(response, ApiResponse<int>.ok(1));
    expect(response.copyWith(code: 500).code, 500);
    expect(response.copyWith(code: 500).data, 1);
    expect(response == ApiResponse<int>.ok(2), isFalse);
  });
}
