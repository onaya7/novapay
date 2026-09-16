/// Thrown when the server refuses a request. The message is written for the
/// customer, because it is what the UI shows.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException($message)';
}
