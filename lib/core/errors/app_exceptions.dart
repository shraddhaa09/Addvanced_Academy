class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

class DuplicateUploadException extends AppException {
  DuplicateUploadException(super.message, [super.code]);
}

class AuthException extends AppException {
  AuthException(super.message, [super.code]);
}
