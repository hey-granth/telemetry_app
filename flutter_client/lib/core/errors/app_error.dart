/// Application error types.
///
/// Provides a consistent error model for the application.
/// All errors from network, parsing, etc. are mapped to these types.
sealed class AppError implements Exception {
  const AppError({
    required this.message,
    this.code,
    this.originalError,
  });

  final String message;
  final String? code;
  final Object? originalError;

  @override
  String toString() => 'AppError($code): $message';
}

/// Network-related errors (connection, timeout, etc.)
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

/// Server-side errors (4xx, 5xx responses)
class ServerError extends AppError {
  const ServerError({
    required super.message,
    super.code = 'SERVER_ERROR',
    super.originalError,
    this.statusCode,
  });

  final int? statusCode;
}

/// Authentication/authorization errors
class AuthError extends AppError {
  const AuthError({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

/// Validation errors (invalid data format)
class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.originalError,
    this.fieldErrors,
  });

  final Map<String, String>? fieldErrors;
}

/// Cache-related errors
class CacheError extends AppError {
  const CacheError({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

/// Unknown/unexpected errors
class UnknownError extends AppError {
  const UnknownError({
    super.message = 'An unexpected error occurred',
    super.code = 'UNKNOWN_ERROR',
    super.originalError,
  });
}
