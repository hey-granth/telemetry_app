/// Abstract provisioning transport
library;

import 'dart:typed_data';

/// Abstract transport interface for provisioning
abstract class ProvisioningTransport {
  /// Connect to the device
  Future<void> connect();

  /// Disconnect from the device
  Future<void> disconnect();

  /// Send data to the device
  Future<void> send(Uint8List data);

  /// Stream of responses from the device
  Stream<Uint8List> get responses;

  /// Whether the transport is connected
  bool get isConnected;

  /// Transport type identifier
  String get transportType;

  /// Dispose resources
  Future<void> dispose();
}

