/// Provisioning configuration
///
/// Contains all configurable values for ESP32 provisioning.
/// No hardcoded values in implementation code.
class ProvisioningConfig {
  const ProvisioningConfig({
    required this.bleServiceUuid,
    required this.sessionCharUuid,
    required this.configCharUuid,
    required this.versionEndpoint,
    required this.sessionEndpoint,
    required this.scanEndpoint,
    required this.configEndpoint,
    required this.applyEndpoint,
    required this.customDataEndpoint,
    required this.connectionTimeout,
    required this.operationTimeout,
    required this.maxRetries,
    required this.scanTimeout,
  });

  /// BLE Service UUID for provisioning
  final String bleServiceUuid;

  /// Session characteristic UUID
  final String sessionCharUuid;

  /// Config characteristic UUID
  final String configCharUuid;

  /// Protocol endpoints
  final String versionEndpoint;
  final String sessionEndpoint;
  final String scanEndpoint;
  final String configEndpoint;
  final String applyEndpoint;
  final String customDataEndpoint;

  /// Timeouts
  final Duration connectionTimeout;
  final Duration operationTimeout;
  final Duration scanTimeout;

  /// Retry configuration
  final int maxRetries;

  /// Default configuration following ESP-IDF provisioning standard
  static const ProvisioningConfig defaultConfig = ProvisioningConfig(
    bleServiceUuid: '0000ffff-0000-1000-8000-00805f9b34fb',
    sessionCharUuid: '0000ff51-0000-1000-8000-00805f9b34fb',
    configCharUuid: '0000ff52-0000-1000-8000-00805f9b34fb',
    versionEndpoint: 'prov-version',
    sessionEndpoint: 'prov-session',
    scanEndpoint: 'prov-scan',
    configEndpoint: 'prov-config',
    applyEndpoint: 'prov-apply',
    customDataEndpoint: 'custom-data',
    connectionTimeout: Duration(seconds: 30),
    operationTimeout: Duration(seconds: 10),
    scanTimeout: Duration(seconds: 15),
    maxRetries: 3,
  );
}

