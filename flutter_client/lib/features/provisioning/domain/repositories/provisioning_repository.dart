/// Provisioning repository interface
library;

import '../entities/provisioning_entities.dart';

/// Repository for provisioning operations
abstract class ProvisioningRepository {
  /// Scan for BLE devices
  Stream<ProvisioningDevice> scanForDevices({Duration? timeout});

  /// Connect to device
  Future<void> connectToDevice(ProvisioningDevice device);

  /// Disconnect from device
  Future<void> disconnect();

  /// Establish secure session
  Future<void> establishSecureSession({
    required String proofOfPossession,
  });

  /// Scan for Wi-Fi networks
  Future<List<WiFiNetwork>> scanWiFiNetworks();

  /// Provision device with Wi-Fi credentials
  Future<void> provisionWiFi(WiFiCredentials credentials);

  /// Get provisioning status
  Future<ProvisioningStatus> getStatus();

  /// Send custom data
  Future<void> sendCustomData(Map<String, String> data);

  /// Parse QR code
  QrProvisioningData parseQrCode(String qrData);

  /// Clean up resources
  Future<void> dispose();
}

