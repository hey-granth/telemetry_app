/// Provisioning error types
library;

import 'package:equatable/equatable.dart';

/// Base class for provisioning errors
sealed class ProvisioningError extends Equatable {
  const ProvisioningError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  /// User-facing error message
  String get userMessage;

  /// Whether this error is recoverable
  bool get isRecoverable;
}

/// Transport-related errors
final class TransportError extends ProvisioningError {
  const TransportError(super.message, {this.isRecoverable = false});

  @override
  final bool isRecoverable;

  @override
  String get userMessage => 'Connection error: $message';
}

/// BLE-specific errors
final class BleError extends TransportError {
  const BleError(super.message, {super.isRecoverable});

  @override
  String get userMessage => 'Bluetooth error: $message';
}

/// Security/cryptography errors
final class SecurityError extends ProvisioningError {
  const SecurityError(super.message);

  @override
  bool get isRecoverable => false;

  @override
  String get userMessage => 'Security error: $message';
}

/// Protocol errors
final class ProtocolError extends ProvisioningError {
  const ProtocolError(super.message, {this.isRecoverable = false});

  @override
  final bool isRecoverable;

  @override
  String get userMessage => 'Protocol error: $message';
}

/// Timeout errors
final class TimeoutError extends ProvisioningError {
  const TimeoutError(super.message);

  @override
  bool get isRecoverable => true;

  @override
  String get userMessage => 'Operation timed out: $message';
}

/// Wi-Fi provisioning errors
final class WiFiProvisioningError extends ProvisioningError {
  const WiFiProvisioningError(super.message, {required this.reason});

  final WiFiFailureReason reason;

  @override
  bool get isRecoverable => reason != WiFiFailureReason.invalidCredentials;

  @override
  String get userMessage {
    switch (reason) {
      case WiFiFailureReason.authFailed:
        return 'Wi-Fi authentication failed. Check password.';
      case WiFiFailureReason.networkNotFound:
        return 'Wi-Fi network not found.';
      case WiFiFailureReason.invalidCredentials:
        return 'Invalid Wi-Fi credentials.';
      case WiFiFailureReason.connectionFailed:
        return 'Failed to connect to Wi-Fi.';
      case WiFiFailureReason.unknown:
        return 'Wi-Fi provisioning failed: $message';
    }
  }

  @override
  List<Object?> get props => [...super.props, reason];
}

enum WiFiFailureReason {
  authFailed,
  networkNotFound,
  invalidCredentials,
  connectionFailed,
  unknown,
}

/// Device errors
final class DeviceError extends ProvisioningError {
  const DeviceError(super.message);

  @override
  bool get isRecoverable => true;

  @override
  String get userMessage => 'Device error: $message';
}


/// Permission errors
final class PermissionError extends ProvisioningError {
  const PermissionError(super.message, {required this.permissionType});

  final PermissionType permissionType;

  @override
  bool get isRecoverable => true;

  @override
  String get userMessage {
    switch (permissionType) {
      case PermissionType.bluetooth:
        return 'Bluetooth permission required';
      case PermissionType.location:
        return 'Location permission required for BLE scanning';
    }
  }

  @override
  List<Object?> get props => [...super.props, permissionType];
}

enum PermissionType {
  bluetooth,
  location,
}

