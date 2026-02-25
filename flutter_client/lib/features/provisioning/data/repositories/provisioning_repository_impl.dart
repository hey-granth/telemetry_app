/// Provisioning repository implementation
library;

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import '../../../../core/config/provisioning_config.dart';
import '../../../../core/errors/provisioning_errors.dart';
import '../../domain/entities/provisioning_entities.dart';
import '../../domain/repositories/provisioning_repository.dart';
import '../protocol/provisioning_protocol.dart';
import '../transports/ble_transport.dart';
import '../transports/provisioning_transport.dart';

/// Implementation of provisioning repository
class ProvisioningRepositoryImpl implements ProvisioningRepository {
  ProvisioningRepositoryImpl({
    required this.config,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final ProvisioningConfig config;
  final Logger _logger;

  ProvisioningTransport? _transport;
  ProvisioningProtocol? _protocol;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  Stream<ProvisioningDevice> scanForDevices({Duration? timeout}) async* {
    _logger.i('Starting BLE scan for provisioning devices');

    try {
      // Check Bluetooth state
      if (await FlutterBluePlus.isSupported == false) {
        throw const BleError('Bluetooth not supported');
      }

      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        throw const BleError('Bluetooth is turned off', isRecoverable: true);
      }

      // Track discovered devices to avoid duplicates
      final discoveredIds = <String>{};
      final scanTimeout = timeout ?? const Duration(seconds: 30);

      _logger.i('Starting BLE scan with ${scanTimeout.inSeconds}s timeout');

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: scanTimeout,
        androidUsesFineLocation: true,
      );

      // Listen to scan results and yield devices as discovered
      await for (final results in FlutterBluePlus.scanResults) {
        for (final result in results) {
          // Filter for provisioning devices
          if (_isProvisioningDevice(result)) {
            final deviceId = result.device.remoteId.toString();

            // Only emit new devices (avoid duplicates)
            if (!discoveredIds.contains(deviceId)) {
              discoveredIds.add(deviceId);
              final device = _mapToProvisioningDevice(result);

              _logger.d('Found provisioning device: ${device.name} (${device.id})');
              yield device;
            }
          }
        }

        // Check if scan is still running
        if (!await FlutterBluePlus.isScanning.first) {
          break;
        }
      }

      _logger.i('BLE scan completed, found ${discoveredIds.length} devices');
      await FlutterBluePlus.stopScan();
    } catch (e) {
      _logger.e('Device scan failed: $e');
      await FlutterBluePlus.stopScan();
      if (e is ProvisioningError) rethrow;
      throw BleError('Device scan failed: $e');
    } finally {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }
  }

  @override
  Future<void> connectToDevice(ProvisioningDevice device) async {
    _logger.i('Connecting to device: ${device.name}');

    try {
      // Clean up existing connections
      await disconnect();

      // Create transport based on device type
      if (device.transportType == TransportType.ble) {
        final bleDevice = BluetoothDevice.fromId(device.id);
        _transport = BleTransport(
          device: bleDevice,
          config: config,
          logger: _logger,
        );
      } else {
        throw const TransportError('SoftAP transport not yet implemented');
      }

      // Connect transport
      await _transport!.connect();

      // Initialize protocol
      _protocol = ProvisioningProtocol(
        transport: _transport!,
        config: config,
        logger: _logger,
      );

      _logger.i('Connected to device');
    } catch (e) {
      _logger.e('Connection failed: $e');
      await disconnect();
      if (e is ProvisioningError) rethrow;
      throw TransportError('Connection failed: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _logger.i('Disconnecting');

    try {
      _protocol?.reset();
      _protocol = null;

      await _transport?.disconnect();
      await _transport?.dispose();
      _transport = null;
    } catch (e) {
      _logger.e('Disconnect error: $e');
    }
  }

  @override
  Future<void> establishSecureSession({
    required String proofOfPossession,
  }) async {
    _logger.i('Establishing secure session');

    if (_protocol == null) {
      throw const ProtocolError('Not connected to device');
    }

    try {
      // Use proof-of-possession as password for Security 2
      await _protocol!.establishSecureSession(
        username: 'espressif',
        password: proofOfPossession,
      );

      _logger.i('Secure session established');
    } catch (e) {
      _logger.e('Secure session failed: $e');
      if (e is ProvisioningError) rethrow;
      throw SecurityError('Session establishment failed: $e');
    }
  }

  @override
  Future<List<WiFiNetwork>> scanWiFiNetworks() async {
    _logger.i('Scanning Wi-Fi networks');

    if (_protocol == null) {
      throw const ProtocolError('Not connected to device');
    }

    try {
      return await _protocol!.scanWiFiNetworks();
    } catch (e) {
      _logger.e('Wi-Fi scan failed: $e');
      if (e is ProvisioningError) rethrow;
      throw ProtocolError('Wi-Fi scan failed: $e', isRecoverable: true);
    }
  }

  @override
  Future<void> provisionWiFi(WiFiCredentials credentials) async {
    _logger.i('Provisioning Wi-Fi');

    if (_protocol == null) {
      throw const ProtocolError('Not connected to device');
    }

    try {
      // Send credentials
      await _protocol!.sendWiFiCredentials(credentials);

      // Apply configuration
      await _protocol!.applyConfiguration();

      // Poll for status
      for (var i = 0; i < config.maxRetries; i++) {
        await Future.delayed(const Duration(seconds: 2));

        final status = await _protocol!.getProvisioningStatus();

        if (status == ProvisioningStatus.success) {
          _logger.i('Provisioning successful');
          return;
        } else if (status == ProvisioningStatus.failed) {
          throw const WiFiProvisioningError(
            'Provisioning failed',
            reason: WiFiFailureReason.connectionFailed,
          );
        }
      }

      throw const TimeoutError('Provisioning status check timed out');
    } catch (e) {
      _logger.e('Provisioning failed: $e');
      if (e is ProvisioningError) rethrow;
      throw WiFiProvisioningError(
        'Provisioning failed: $e',
        reason: WiFiFailureReason.unknown,
      );
    }
  }

  @override
  Future<ProvisioningStatus> getStatus() async {
    if (_protocol == null) {
      throw const ProtocolError('Not connected to device');
    }

    return await _protocol!.getProvisioningStatus();
  }

  @override
  Future<void> sendCustomData(Map<String, String> data) async {
    if (_protocol == null) {
      throw const ProtocolError('Not connected to device');
    }

    await _protocol!.sendCustomData(data);
  }


  @override
  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await disconnect();
  }

  /// Check if scan result is a provisioning device
  bool _isProvisioningDevice(ScanResult result) {
    // Check for provisioning service UUID
    for (final serviceUuid in result.advertisementData.serviceUuids) {
      if (serviceUuid.toString().toLowerCase() == config.bleServiceUuid.toLowerCase()) {
        return true;
      }
    }

    // Check device name prefix
    final name = result.device.platformName;
    return name.startsWith('PROV_') || name.startsWith('ESP32');
  }

  /// Map scan result to provisioning device
  ProvisioningDevice _mapToProvisioningDevice(ScanResult result) {
    return ProvisioningDevice(
      id: result.device.remoteId.toString(),
      name: result.device.platformName,
      rssi: result.rssi,
      transportType: TransportType.ble,
      serviceUuid: config.bleServiceUuid,
    );
  }
}

