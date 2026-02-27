/// Platform-aware permission helper
///
/// Handles permissions gracefully across different platforms.
/// Only Bluetooth permissions are required for BLE provisioning.
library;

import 'dart:io' show Platform;
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thrown when the native permission handler plugin is not registered/available.
class PermissionHandlerUnavailableException implements Exception {
  final String message;
  PermissionHandlerUnavailableException(
      [this.message = 'permission_handler plugin not available']);
  @override
  String toString() => 'PermissionHandlerUnavailableException: $message';
}

final _logger = Logger();

/// Helper class for checking and requesting permissions in a platform-aware manner.
///
/// This app only requires Bluetooth permissions (scan + connect).
/// No Contacts, Location, or other permissions are requested.
class PermissionHelper {
  /// Check if permission handling is supported on current platform
  static bool get isPermissionHandlingSupported {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Check Bluetooth scan permission status
  static Future<PermissionStatus> checkBluetoothScan() async {
    if (!isPermissionHandlingSupported) {
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

  /// Check Bluetooth connect permission status
  static Future<PermissionStatus> checkBluetoothConnect() async {
    if (!isPermissionHandlingSupported) {
      return PermissionStatus.granted;
    }

    try {
      return await Permission.bluetoothConnect.status;
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        _logger.w(
            'Permission plugin missing when checking bluetoothConnect: $e');
        throw PermissionHandlerUnavailableException();
      }
      _logger.w('Error checking Bluetooth connect permission: $e');
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
        _logger
            .w('Permission plugin missing when requesting bluetoothScan: $e');
        throw PermissionHandlerUnavailableException();
      }
      _logger.w('Error requesting Bluetooth scan permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request Bluetooth connect permission
  static Future<PermissionStatus> requestBluetoothConnect() async {
    if (!isPermissionHandlingSupported) {
      return PermissionStatus.granted;
    }

    try {
      return await Permission.bluetoothConnect.request();
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        _logger.w(
            'Permission plugin missing when requesting bluetoothConnect: $e');
        throw PermissionHandlerUnavailableException();
      }
      _logger.w('Error requesting Bluetooth connect permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Check and request all required permissions for BLE provisioning.
  ///
  /// Only requests bluetoothScan and bluetoothConnect.
  /// No Location or Contacts permissions are requested.
  static Future<bool> checkAndRequestBlePermissions() async {
    if (!isPermissionHandlingSupported) {
      _logger.i('Platform does not require permission handling');
      return true;
    }

    try {
      // Check current status of both Bluetooth permissions
      final scanStatus = await checkBluetoothScan();
      final connectStatus = await checkBluetoothConnect();

      if (scanStatus.isGranted && connectStatus.isGranted) {
        _logger.i('All BLE permissions already granted');
        return true;
      }

      // Build list of permissions that still need to be requested
      final permissionsToRequest = <Permission>[];
      if (!scanStatus.isGranted) {
        permissionsToRequest.add(Permission.bluetoothScan);
      }
      if (!connectStatus.isGranted) {
        permissionsToRequest.add(Permission.bluetoothConnect);
      }

      _logger.i('Requesting BLE permissions: $permissionsToRequest');

      // Batch-request all needed permissions at once
      final results = await permissionsToRequest.request();

      final allGranted = results.values.every((status) => status.isGranted);

      if (!allGranted) {
        _logger.w('Not all BLE permissions granted: $results');

        // Check if any are permanently denied → guide user to settings
        final permanentlyDenied = results.entries
            .where((e) => e.value.isPermanentlyDenied)
            .map((e) => e.key)
            .toList();
        if (permanentlyDenied.isNotEmpty) {
          _logger.w(
            'Permanently denied permissions: $permanentlyDenied. '
            'User must enable them in app settings.',
          );
        }
      }

      return allGranted;
    } on PermissionHandlerUnavailableException {
      _logger.w('Permission handler plugin not available on this platform');
      rethrow;
    } catch (e) {
      _logger.w('Error in permission check/request: $e');
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
