class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class ApiException extends AppException {
  const ApiException(
    super.message, {
    required this.statusCode,
  });

  final int statusCode;
}
