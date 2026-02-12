/// Platform-aware permission helper
///
/// Handles permissions gracefully across different platforms
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:permission_handler/permission_handler.dart';

/// Helper class for checking and requesting permissions in a platform-aware manner
class PermissionHelper {
  /// Check if permission handling is supported on current platform
  static bool get isPermissionHandlingSupported {
    if (kIsWeb) return false;

    // Permission handler primarily works on mobile platforms
    return Platform.isAndroid || Platform.isIOS;
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
      debugPrint('Error checking Bluetooth scan permission: $e');
      return PermissionStatus.granted; // Assume granted on error
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
      debugPrint('Error checking location permission: $e');
      return PermissionStatus.granted;
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
      debugPrint('Error requesting Bluetooth scan permission: $e');
      return PermissionStatus.granted;
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
      debugPrint('Error requesting location permission: $e');
      return PermissionStatus.granted;
    }
  }

  /// Check and request all required permissions for BLE provisioning
  static Future<bool> checkAndRequestBlePermissions() async {
    if (!isPermissionHandlingSupported) {
      debugPrint('Platform does not require permission handling');
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
    } catch (e) {
      debugPrint('Error in permission check/request: $e');
      // On error, assume permissions are available (e.g., desktop platforms)
      return true;
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


