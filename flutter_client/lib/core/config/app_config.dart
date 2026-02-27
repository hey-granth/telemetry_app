/// Application configuration.
///
/// Centralized configuration for the application.
/// Values can be overridden via environment or build-time configuration.
class AppConfig {
  AppConfig._();

  /// Application name
  static const String appName = 'Telemetry';

  /// Backend host IP address (local network)
  static const String host = '172.23.19.223';

  /// Backend port
  static const int port = 8000;

  /// Backend base URL
  static const String baseUrl = 'http://$host:$port';

  /// Backend API base URL
  static const String apiBaseUrl = '$baseUrl/api/v1';

  /// WebSocket base URL
  static const String wsBaseUrl = 'ws://$host:$port/api/v1';

  /// Request timeout in seconds
  static const int requestTimeoutSeconds = 30;

  /// WebSocket reconnect delay in seconds
  static const int wsReconnectDelaySeconds = 5;

  /// Maximum retry attempts for failed requests
  static const int maxRetryAttempts = 3;

  /// Default polling interval in seconds (for fallback when WebSocket unavailable)
  static const int pollingIntervalSeconds = 10;

  /// Chart default time range
  static const String defaultTimeRange = '24h';

  /// Maximum readings to display in charts
  static const int maxChartDataPoints = 100;
}
