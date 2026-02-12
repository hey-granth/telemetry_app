/// BLE transport implementation for provisioning
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import '../../../../core/config/provisioning_config.dart';
import '../../../../core/errors/provisioning_errors.dart';
import 'provisioning_transport.dart';

/// BLE-based provisioning transport
class BleTransport implements ProvisioningTransport {
  BleTransport({
    required this.device,
    required this.config,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final BluetoothDevice device;
  final ProvisioningConfig config;
  final Logger _logger;

  BluetoothCharacteristic? _sessionChar;
  BluetoothCharacteristic? _configChar;

  final _responseController = StreamController<Uint8List>.broadcast();
  StreamSubscription<List<int>>? _subscription;

  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  @override
  String get transportType => 'BLE';

  @override
  Stream<Uint8List> get responses => _responseController.stream;

  @override
  Future<void> connect() async {
    try {
      _logger.i('Connecting to BLE device: ${device.platformName}');

      // Connect with timeout
      await device.connect(
        timeout: config.connectionTimeout,
        autoConnect: false,
      );

      // Discover services
      final services = await device.discoverServices();

      // Find provisioning service
      final provService = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == config.bleServiceUuid.toLowerCase(),
        orElse: () => throw const BleError('Provisioning service not found'),
      );

      // Find characteristics
      _sessionChar = provService.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == config.sessionCharUuid.toLowerCase(),
        orElse: () => throw const BleError('Session characteristic not found'),
      );

      _configChar = provService.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == config.configCharUuid.toLowerCase(),
        orElse: () => throw const BleError('Config characteristic not found'),
      );

      // Enable notifications on session characteristic
      if (_sessionChar!.properties.notify) {
        await _sessionChar!.setNotifyValue(true);
        _subscription = _sessionChar!.lastValueStream.listen(
          (value) {
            if (value.isNotEmpty) {
              _responseController.add(Uint8List.fromList(value));
            }
          },
          onError: (error) {
            _logger.e('BLE notification error: $error');
            _responseController.addError(BleError(error.toString()));
          },
        );
      } else {
        throw const BleError('Session characteristic does not support notifications');
      }

      _isConnected = true;
      _logger.i('BLE connection established');
    } catch (e) {
      _logger.e('BLE connection failed: $e');
      await disconnect();
      if (e is ProvisioningError) rethrow;
      throw BleError('Connection failed: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      _logger.i('Disconnecting BLE device');

      await _subscription?.cancel();
      _subscription = null;

      if (_sessionChar != null && _sessionChar!.properties.notify) {
        try {
          await _sessionChar!.setNotifyValue(false);
        } catch (e) {
          _logger.w('Failed to disable notifications: $e');
        }
      }

      await device.disconnect();
      _isConnected = false;

      _logger.i('BLE disconnected');
    } catch (e) {
      _logger.e('BLE disconnect error: $e');
      _isConnected = false;
    }
  }

  @override
  Future<void> send(Uint8List data) async {
    if (!_isConnected) {
      throw const BleError('Not connected');
    }

    if (_configChar == null) {
      throw const BleError('Config characteristic not available');
    }

    try {
      _logger.d('Sending ${data.length} bytes via BLE');

      // Write with response for reliability
      await _configChar!.write(
        data,
        withoutResponse: false,
        timeout: config.operationTimeout.inSeconds,
      );

      _logger.d('Data sent successfully');
    } catch (e) {
      _logger.e('BLE send failed: $e');
      throw BleError('Send failed: $e', isRecoverable: true);
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _responseController.close();
  }
}

