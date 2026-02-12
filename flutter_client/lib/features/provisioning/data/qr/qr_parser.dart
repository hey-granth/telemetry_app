/// QR code parser for provisioning
library;

import 'dart:convert';
import '../../../../core/errors/provisioning_errors.dart';
import '../../domain/entities/provisioning_entities.dart';

/// Parses QR codes for provisioning
class QrCodeParser {
  /// Parse QR code data
  static QrProvisioningData parse(String qrData) {
    try {
      // Try JSON format first
      if (qrData.startsWith('{')) {
        return _parseJson(qrData);
      }

      // Try key-value format
      if (qrData.contains(':')) {
        return _parseKeyValue(qrData);
      }

      throw const QrCodeError('Unsupported QR code format');
    } catch (e) {
      if (e is ProvisioningError) rethrow;
      throw QrCodeError('Failed to parse QR code: $e');
    }
  }

  static QrProvisioningData _parseJson(String data) {
    final json = jsonDecode(data) as Map<String, dynamic>;

    final name = json['name'] as String?;
    final pop = json['pop'] as String?;
    final transport = json['transport'] as String?;

    if (name == null || pop == null || transport == null) {
      throw const QrCodeError('Missing required fields');
    }

    return QrProvisioningData(
      version: json['ver'] as String? ?? 'v1',
      transportType: transport == 'ble' ? TransportType.ble : TransportType.softap,
      serviceName: name,
      proofOfPossession: pop,
      password: json['password'] as String?,
    );
  }

  static QrProvisioningData _parseKeyValue(String data) {
    final pairs = data.split(',');
    final map = <String, String>{};

    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        map[parts[0].trim()] = parts[1].trim();
      }
    }

    final name = map['name'];
    final pop = map['pop'];
    final transport = map['transport'];

    if (name == null || pop == null || transport == null) {
      throw const QrCodeError('Missing required fields');
    }

    return QrProvisioningData(
      version: map['ver'] ?? 'v1',
      transportType: transport == 'ble' ? TransportType.ble : TransportType.softap,
      serviceName: name,
      proofOfPossession: pop,
      password: map['password'],
    );
  }
}

