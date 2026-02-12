/// Protocol message types and encoders
library;

import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Base protocol message
abstract class ProtocolMessage {
  /// Encode message to bytes
  Uint8List encode();
}

/// Protocol request wrapper
class ProvisioningRequest extends Equatable implements ProtocolMessage {
  const ProvisioningRequest({
    required this.endpoint,
    required this.payload,
  });

  final String endpoint;
  final Uint8List payload;

  @override
  List<Object?> get props => [endpoint, payload];

  @override
  Uint8List encode() {
    // Simple frame format:
    // [endpoint_length (1 byte)][endpoint][payload_length (2 bytes)][payload]
    final endpointBytes = Uint8List.fromList(endpoint.codeUnits);
    final buffer = BytesBuilder();

    buffer.addByte(endpointBytes.length);
    buffer.add(endpointBytes);
    buffer.addByte((payload.length >> 8) & 0xFF);
    buffer.addByte(payload.length & 0xFF);
    buffer.add(payload);

    return buffer.toBytes();
  }
}

/// Protocol response wrapper
class ProvisioningResponse extends Equatable {
  const ProvisioningResponse({
    required this.status,
    required this.payload,
  });

  final int status;
  final Uint8List payload;

  bool get isSuccess => status == 0;

  @override
  List<Object?> get props => [status, payload];

  /// Decode response from bytes
  static ProvisioningResponse decode(Uint8List data) {
    if (data.length < 3) {
      throw ArgumentError('Response too short');
    }

    final status = data[0];
    final payloadLength = (data[1] << 8) | data[2];

    if (data.length < 3 + payloadLength) {
      throw ArgumentError('Invalid payload length');
    }

    final payload = Uint8List.fromList(data.sublist(3, 3 + payloadLength));

    return ProvisioningResponse(
      status: status,
      payload: payload,
    );
  }
}

/// Session request data
class SessionRequestData extends Equatable implements ProtocolMessage {
  const SessionRequestData({
    required this.clientPublicKey,
    required this.clientProof,
  });

  final Uint8List clientPublicKey;
  final Uint8List clientProof;

  @override
  List<Object?> get props => [clientPublicKey, clientProof];

  @override
  Uint8List encode() {
    // Format: [key_length (2 bytes)][key][proof_length (2 bytes)][proof]
    final buffer = BytesBuilder();

    buffer.addByte((clientPublicKey.length >> 8) & 0xFF);
    buffer.addByte(clientPublicKey.length & 0xFF);
    buffer.add(clientPublicKey);

    buffer.addByte((clientProof.length >> 8) & 0xFF);
    buffer.addByte(clientProof.length & 0xFF);
    buffer.add(clientProof);

    return buffer.toBytes();
  }
}

/// Session response data
class SessionResponseData extends Equatable {
  const SessionResponseData({
    required this.serverPublicKey,
    required this.serverProof,
    required this.salt,
  });

  final Uint8List serverPublicKey;
  final Uint8List serverProof;
  final Uint8List salt;

  @override
  List<Object?> get props => [serverPublicKey, serverProof, salt];

  /// Decode from bytes
  static SessionResponseData decode(Uint8List data) {
    var offset = 0;

    // Read server public key
    final keyLength = (data[offset] << 8) | data[offset + 1];
    offset += 2;
    final serverPublicKey = Uint8List.fromList(data.sublist(offset, offset + keyLength));
    offset += keyLength;

    // Read server proof
    final proofLength = (data[offset] << 8) | data[offset + 1];
    offset += 2;
    final serverProof = Uint8List.fromList(data.sublist(offset, offset + proofLength));
    offset += proofLength;

    // Read salt
    final saltLength = (data[offset] << 8) | data[offset + 1];
    offset += 2;
    final salt = Uint8List.fromList(data.sublist(offset, offset + saltLength));

    return SessionResponseData(
      serverPublicKey: serverPublicKey,
      serverProof: serverProof,
      salt: salt,
    );
  }
}

/// Wi-Fi scan request
class WiFiScanRequest extends Equatable implements ProtocolMessage {
  const WiFiScanRequest({this.passive = false});

  final bool passive;

  @override
  List<Object?> get props => [passive];

  @override
  Uint8List encode() {
    return Uint8List.fromList([passive ? 1 : 0]);
  }
}

/// Wi-Fi scan result entry
class WiFiScanEntry extends Equatable {
  const WiFiScanEntry({
    required this.ssid,
    required this.rssi,
    required this.channel,
    required this.authMode,
  });

  final String ssid;
  final int rssi;
  final int channel;
  final int authMode;

  @override
  List<Object?> get props => [ssid, rssi, channel, authMode];
}

/// Wi-Fi scan response
class WiFiScanResponse extends Equatable {
  const WiFiScanResponse({
    required this.entries,
  });

  final List<WiFiScanEntry> entries;

  @override
  List<Object?> get props => [entries];

  /// Decode scan results
  static WiFiScanResponse decode(Uint8List data) {
    final entries = <WiFiScanEntry>[];
    var offset = 0;

    // Number of entries
    final count = data[offset];
    offset++;

    for (var i = 0; i < count; i++) {
      // SSID length and value
      final ssidLen = data[offset];
      offset++;
      final ssid = String.fromCharCodes(data.sublist(offset, offset + ssidLen));
      offset += ssidLen;

      // RSSI (signed byte)
      final rssi = data[offset].toSigned(8);
      offset++;

      // Channel
      final channel = data[offset];
      offset++;

      // Auth mode
      final authMode = data[offset];
      offset++;

      entries.add(WiFiScanEntry(
        ssid: ssid,
        rssi: rssi,
        channel: channel,
        authMode: authMode,
      ));
    }

    return WiFiScanResponse(entries: entries);
  }
}

/// Wi-Fi configuration request
class WiFiConfigRequest extends Equatable implements ProtocolMessage {
  const WiFiConfigRequest({
    required this.ssid,
    required this.password,
  });

  final String ssid;
  final String password;

  @override
  List<Object?> get props => [ssid, password];

  @override
  Uint8List encode() {
    final ssidBytes = Uint8List.fromList(ssid.codeUnits);
    final passwordBytes = Uint8List.fromList(password.codeUnits);

    final buffer = BytesBuilder();

    // SSID
    buffer.addByte(ssidBytes.length);
    buffer.add(ssidBytes);

    // Password
    buffer.addByte(passwordBytes.length);
    buffer.add(passwordBytes);

    return buffer.toBytes();
  }
}

/// Apply configuration request
class ApplyConfigRequest extends Equatable implements ProtocolMessage {
  const ApplyConfigRequest();

  @override
  List<Object?> get props => [];

  @override
  Uint8List encode() {
    return Uint8List.fromList([0x01]); // Apply command
  }
}

/// Provisioning status response
class ProvisioningStatusResponse extends Equatable {
  const ProvisioningStatusResponse({
    required this.state,
    this.failureReason,
  });

  final int state;
  final int? failureReason;

  bool get isSuccess => state == 1;
  bool get isFailed => state == 2;
  bool get isInProgress => state == 0;

  @override
  List<Object?> get props => [state, failureReason];

  /// Decode status
  static ProvisioningStatusResponse decode(Uint8List data) {
    final state = data[0];
    final failureReason = data.length > 1 ? data[1] : null;

    return ProvisioningStatusResponse(
      state: state,
      failureReason: failureReason,
    );
  }
}

/// Custom data request
class CustomDataRequest extends Equatable implements ProtocolMessage {
  const CustomDataRequest({
    required this.data,
  });

  final Map<String, String> data;

  @override
  List<Object?> get props => [data];

  @override
  Uint8List encode() {
    final buffer = BytesBuilder();

    // Number of entries
    buffer.addByte(data.length);

    for (final entry in data.entries) {
      final keyBytes = Uint8List.fromList(entry.key.codeUnits);
      final valueBytes = Uint8List.fromList(entry.value.codeUnits);

      // Key
      buffer.addByte(keyBytes.length);
      buffer.add(keyBytes);

      // Value
      buffer.addByte((valueBytes.length >> 8) & 0xFF);
      buffer.addByte(valueBytes.length & 0xFF);
      buffer.add(valueBytes);
    }

    return buffer.toBytes();
  }
}

