import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../errors/app_error.dart';
import '../errors/result.dart';

/// HTTP client for REST API communication.
///
/// Wraps Dio with consistent error handling, logging, and retry logic.
/// All network errors are mapped to [AppError] types.
class ApiClient {
  ApiClient({
    String? baseUrl,
    Duration? timeout,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
            connectTimeout:
                timeout ?? Duration(seconds: AppConfig.requestTimeoutSeconds),
            receiveTimeout:
                timeout ?? Duration(seconds: AppConfig.requestTimeoutSeconds),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(_LoggingInterceptor(_logger));
  }

  final Dio _dio;
  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  /// Set API key for authenticated requests
  void setApiKey(String apiKey) {
    _dio.options.headers['X-API-Key'] = apiKey;
  }

  /// Clear API key
  void clearApiKey() {
    _dio.options.headers.remove('X-API-Key');
  }

  /// Perform GET request
  Future<Result<T, AppError>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, parser);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// Perform POST request
  Future<Result<T, AppError>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, parser);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// Perform DELETE request
  Future<Result<T, AppError>> delete<T>(
    String path, {
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(path);
      return _handleResponse(response, parser);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  Result<T, AppError> _handleResponse<T>(
    Response<dynamic> response,
    T Function(dynamic)? parser,
  ) {
    final data = response.data;

    // Check if response uses our envelope format
    if (data is Map<String, dynamic>) {
      final success = data['success'] as bool? ?? true;

      if (!success) {
        return Failure(
          ServerError(
            message: data['error'] as String? ?? 'Unknown error',
            code: data['code'] as String?,
            statusCode: response.statusCode,
          ),
        );
      }

      // Extract data from envelope
      final payload = data['data'];

      if (parser != null) {
        try {
          return Success(parser(payload));
        } catch (e) {
          return Failure(
            ValidationError(
              message: 'Failed to parse response',
              originalError: e,
            ),
          );
        }
      }

      return Success(payload as T);
    }

    // Raw response without envelope
    if (parser != null) {
      try {
        return Success(parser(data));
      } catch (e) {
        return Failure(
          ValidationError(
            message: 'Failed to parse response',
            originalError: e,
          ),
        );
      }
    }

    return Success(data as T);
  }

  AppError _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError(
          message: 'Request timed out',
          code: 'TIMEOUT',
          originalError: e,
        );

      case DioExceptionType.connectionError:
        return NetworkError(
          message: 'Unable to connect to server',
          code: 'CONNECTION_ERROR',
          originalError: e,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        String message = 'Server error';
        String? code;

        if (data is Map<String, dynamic>) {
          message =
              data['error'] as String? ?? data['detail'] as String? ?? message;
          code = data['code'] as String?;
        }

        if (statusCode == 401 || statusCode == 403) {
          return AuthError(
            message: message,
            code: code,
            originalError: e,
          );
        }

        return ServerError(
          message: message,
          code: code,
          statusCode: statusCode,
          originalError: e,
        );

      case DioExceptionType.cancel:
        return NetworkError(
          message: 'Request cancelled',
          code: 'CANCELLED',
          originalError: e,
        );

      default:
        return UnknownError(originalError: e);
    }
  }
}

/// Logging interceptor for Dio requests
class _LoggingInterceptor extends Interceptor {
  _LoggingInterceptor(this._logger);

  final Logger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('✕ ${err.type} ${err.requestOptions.uri}: ${err.message}');
    handler.next(err);
  }
}
