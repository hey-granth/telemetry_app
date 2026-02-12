/// Domain entities for provisioning
library;

import 'package:equatable/equatable.dart';

/// Discovered provisioning device
class ProvisioningDevice extends Equatable {
  const ProvisioningDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.transportType,
    this.serviceUuid,
    this.proofOfPossession,
  });

  final String id;
  final String name;
  final int rssi;
  final TransportType transportType;
  final String? serviceUuid;
  final String? proofOfPossession;

  @override
  List<Object?> get props => [id, name, rssi, transportType, serviceUuid, proofOfPossession];

  ProvisioningDevice copyWith({
    String? id,
    String? name,
    int? rssi,
    TransportType? transportType,
    String? serviceUuid,
    String? proofOfPossession,
  }) {
    return ProvisioningDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      transportType: transportType ?? this.transportType,
      serviceUuid: serviceUuid ?? this.serviceUuid,
      proofOfPossession: proofOfPossession ?? this.proofOfPossession,
    );
  }
}

/// Transport type
enum TransportType {
  ble,
  softap,
}

/// Wi-Fi network information
class WiFiNetwork extends Equatable {
  const WiFiNetwork({
    required this.ssid,
    required this.rssi,
    required this.authMode,
    required this.channel,
  });

  final String ssid;
  final int rssi;
  final WiFiAuthMode authMode;
  final int channel;

  bool get isSecure => authMode != WiFiAuthMode.open;

  @override
  List<Object?> get props => [ssid, rssi, authMode, channel];
}

/// Wi-Fi authentication mode
enum WiFiAuthMode {
  open,
  wep,
  wpaPsk,
  wpa2Psk,
  wpaWpa2Psk,
  wpa2Enterprise,
  wpa3Psk,
  wpa2Wpa3Psk,
}

/// Wi-Fi credentials
class WiFiCredentials extends Equatable {
  const WiFiCredentials({
    required this.ssid,
    required this.password,
  });

  final String ssid;
  final String password;

  @override
  List<Object?> get props => [ssid, password];
}

/// Provisioning session information
class ProvisioningSession extends Equatable {
  const ProvisioningSession({
    required this.device,
    required this.securityVersion,
    required this.capabilities,
    this.sessionKey,
  });

  final ProvisioningDevice device;
  final int securityVersion;
  final List<String> capabilities;
  final List<int>? sessionKey;

  bool get isSecure => sessionKey != null;

  @override
  List<Object?> get props => [device, securityVersion, capabilities, sessionKey];

  ProvisioningSession copyWith({
    ProvisioningDevice? device,
    int? securityVersion,
    List<String>? capabilities,
    List<int>? sessionKey,
  }) {
    return ProvisioningSession(
      device: device ?? this.device,
      securityVersion: securityVersion ?? this.securityVersion,
      capabilities: capabilities ?? this.capabilities,
      sessionKey: sessionKey ?? this.sessionKey,
    );
  }
}

/// Provisioning status
enum ProvisioningStatus {
  idle,
  connected,
  configReceived,
  configApplied,
  success,
  failed,
}

/// QR code data
class QrProvisioningData extends Equatable {
  const QrProvisioningData({
    required this.version,
    required this.transportType,
    required this.serviceName,
    required this.proofOfPossession,
    this.password,
  });

  final String version;
  final TransportType transportType;
  final String serviceName;
  final String proofOfPossession;
  final String? password;

  @override
  List<Object?> get props => [version, transportType, serviceName, proofOfPossession, password];
}

