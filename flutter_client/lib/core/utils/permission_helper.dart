/// Platform-aware permission helper
///
/// Handles permissions gracefully across different platforms
library;

import 'dart:io' show Platform;
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thrown when the native permission handler plugin is not registered/available.
class PermissionHandlerUnavailableException implements Exception {
  final String message;
  PermissionHandlerUnavailableException([this.message = 'permission_handler plugin not available']);
  @override
  String toString() => 'PermissionHandlerUnavailableException: $message';
}

final _logger = Logger();

/// Helper class for checking and requesting permissions in a platform-aware manner
class PermissionHelper {
  /// Check if permission handling is supported on current platform
  static bool get isPermissionHandlingSupported {
    // Permission handler primarily works on mobile platforms
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      // Platform may not be available (e.g., web), assume unsupported
      return false;
    }
  }

  /// Check Bluetooth scan permission status
  static Future<PermissionStatus> checkBluetoothScan() async {
    if (!isPermissionHandlingSupported) {
      // On unsupported platforms, assume granted
      return PermissionStatus.granted;
    }

    try {
      return await Permission.bluetoothScan.status;
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        _logger.w('Permission plugin missing when checking bluetoothScan: $e');
        throw PermissionHandlerUnavailableException();
      }
      _logger.w('Error checking Bluetooth scan permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Check location permission status
  static Future<PermissionStatus> checkLocation() async {
    if (!isPermissionHandlingSupported) {
      return PermissionStatus.granted;
    }

    try {
      return await Permission.location.status;
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        _logger.w('Permission plugin missing when checking location: $e');
        throw PermissionHandlerUnavailableException();
      }
      _logger.w('Error checking location permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request Bluetooth scan permission
  static Future<PermissionStatus> requestBluetoothScan() async {
    if (!isPermissionHandlingSupported) {
      return PermissionStatus.granted;
    }

    try {
      return await Permission.bluetoothScan.request();
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        _logger.w('Permission plugin missing when requesting bluetoothScan: $e');
        throw PermissionHandlerUnavailableException();
      }
      _logger.w('Error requesting Bluetooth scan permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request location permission
  static Future<PermissionStatus> requestLocation() async {
    if (!isPermissionHandlingSupported) {
      return PermissionStatus.granted;
    }

    try {
      return await Permission.location.request();
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        _logger.w('Permission plugin missing when requesting location: $e');
        throw PermissionHandlerUnavailableException();
      }
      _logger.w('Error requesting location permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Check and request all required permissions for BLE provisioning
  static Future<bool> checkAndRequestBlePermissions() async {
    if (!isPermissionHandlingSupported) {
      _logger.i('Platform does not require permission handling');
      return true; // Assume permissions are granted
    }

    try {
      final bluetoothStatus = await checkBluetoothScan();
      final locationStatus = await checkLocation();

      if (bluetoothStatus.isGranted && locationStatus.isGranted) {
        return true;
      }

      // Request permissions if not granted
      final bluetoothResult = await requestBluetoothScan();
      final locationResult = await requestLocation();

      return bluetoothResult.isGranted && locationResult.isGranted;
    } on PermissionHandlerUnavailableException {
      // Surface a clear error to the caller so the UI can show a retry path.
      _logger.w('Permission handler plugin not available on this platform');
      rethrow;
    } catch (e) {
      _logger.w('Error in permission check/request: $e');
      // Do not assume granted on unexpected errors; require explicit grant.
      return false;
    }
  }

  /// Get a user-friendly message about permission status
  static String getPermissionMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied. Please grant permission in settings.';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied. Please enable in app settings.';
      case PermissionStatus.restricted:
        return 'Permission restricted by system.';
      case PermissionStatus.limited:
        return 'Permission granted with limitations.';
      case PermissionStatus.provisional:
        return 'Permission provisionally granted.';
    }
  }
}
