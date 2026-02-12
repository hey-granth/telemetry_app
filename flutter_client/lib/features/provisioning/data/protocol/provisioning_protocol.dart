/// Provisioning protocol handler
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import '../../../../core/config/provisioning_config.dart';
import '../../../../core/crypto/aes_encryption.dart';
import '../../../../core/crypto/srp_client.dart';
import '../../../../core/crypto/crypto_types.dart';
import '../../../../core/errors/provisioning_errors.dart';
import '../../domain/entities/provisioning_entities.dart';
import '../transports/provisioning_transport.dart';
import 'protocol_messages.dart';

/// Handles provisioning protocol operations
class ProvisioningProtocol {
  ProvisioningProtocol({
    required this.transport,
    required this.config,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final ProvisioningTransport transport;
  final ProvisioningConfig config;
  final Logger _logger;

  SrpClient? _srpClient;
  AesEncryption? _encryption;
  bool _isSecureSessionEstablished = false;

  /// Establish secure session using Security 2
  Future<void> establishSecureSession({
    required String username,
    required String password,
  }) async {
    _logger.i('Establishing secure session');

    try {
      // Initialize SRP client
      _srpClient = SrpClient(
        username: username,
        password: password,
      );

      // Generate client public key
      final clientPublicKey = _srpClient!.generateClientPublic();
      _logger.d('Generated client public key');

      // Send session request
      final sessionRequest = SessionRequestData(
        clientPublicKey: clientPublicKey,
        clientProof: Uint8List(0), // Will be computed after receiving server key
      );

      final request = ProvisioningRequest(
        endpoint: config.sessionEndpoint,
        payload: sessionRequest.encode(),
      );

      // Send and wait for response
      final responseData = await _sendAndReceive(request.encode());
      final response = ProvisioningResponse.decode(responseData);

      if (!response.isSuccess) {
        throw const SecurityError('Session establishment failed');
      }

      // Parse session response
      final sessionResponse = SessionResponseData.decode(response.payload);
      _logger.d('Received server public key and salt');

      // Compute session key
      final handshakeResult = _srpClient!.computeSessionKey(
        serverPublicKey: sessionResponse.serverPublicKey,
        salt: sessionResponse.salt,
      );

      // Verify server proof
      if (!_srpClient!.verifyServerProof(
        sessionResponse.serverProof,
        sessionResponse.salt,
        sessionResponse.serverPublicKey,
      )) {
        throw const SecurityError('Server proof verification failed');
      }

      _logger.i('Server verified successfully');

      // Initialize encryption
      _encryption = AesEncryption(sessionKey: handshakeResult.sessionKey);
      _isSecureSessionEstablished = true;

      _logger.i('Secure session established');
    } catch (e) {
      _logger.e('Secure session failed: $e');
      if (e is ProvisioningError) rethrow;
      throw SecurityError('Session establishment failed: $e');
    }
  }

  /// Scan for available Wi-Fi networks
  Future<List<WiFiNetwork>> scanWiFiNetworks() async {
    _logger.i('Scanning Wi-Fi networks');

    try {
      final scanRequest = WiFiScanRequest();
      final payload = _encryptIfSecure(scanRequest.encode());

      final request = ProvisioningRequest(
        endpoint: config.scanEndpoint,
        payload: payload,
      );

      final responseData = await _sendAndReceive(
        request.encode(),
        timeout: config.scanTimeout,
      );

      final response = ProvisioningResponse.decode(responseData);

      if (!response.isSuccess) {
        throw const ProtocolError('Wi-Fi scan failed');
      }

      final decryptedPayload = _decryptIfSecure(response.payload);
      final scanResponse = WiFiScanResponse.decode(decryptedPayload);

      // Convert to domain entities
      final networks = scanResponse.entries.map((entry) {
        return WiFiNetwork(
          ssid: entry.ssid,
          rssi: entry.rssi,
          channel: entry.channel,
          authMode: _mapAuthMode(entry.authMode),
        );
      }).toList();

      _logger.i('Found ${networks.length} Wi-Fi networks');
      return networks;
    } catch (e) {
      _logger.e('Wi-Fi scan failed: $e');
      if (e is ProvisioningError) rethrow;
      throw ProtocolError('Wi-Fi scan failed: $e', isRecoverable: true);
    }
  }

  /// Send Wi-Fi credentials
  Future<void> sendWiFiCredentials(WiFiCredentials credentials) async {
    _logger.i('Sending Wi-Fi credentials for SSID: ${credentials.ssid}');

    if (!_isSecureSessionEstablished) {
      throw const SecurityError('Secure session not established');
    }

    try {
      final configRequest = WiFiConfigRequest(
        ssid: credentials.ssid,
        password: credentials.password,
      );

      final payload = _encryptIfSecure(configRequest.encode());

      final request = ProvisioningRequest(
        endpoint: config.configEndpoint,
        payload: payload,
      );

      final responseData = await _sendAndReceive(request.encode());
      final response = ProvisioningResponse.decode(responseData);

      if (!response.isSuccess) {
        throw const WiFiProvisioningError(
          'Failed to send credentials',
          reason: WiFiFailureReason.invalidCredentials,
        );
      }

      _logger.i('Credentials sent successfully');
    } catch (e) {
      _logger.e('Failed to send credentials: $e');
      if (e is ProvisioningError) rethrow;
      throw WiFiProvisioningError(
        'Failed to send credentials: $e',
        reason: WiFiFailureReason.connectionFailed,
      );
    }
  }

  /// Apply configuration
  Future<void> applyConfiguration() async {
    _logger.i('Applying configuration');

    try {
      final applyRequest = ApplyConfigRequest();
      final payload = _encryptIfSecure(applyRequest.encode());

      final request = ProvisioningRequest(
        endpoint: config.applyEndpoint,
        payload: payload,
      );

      final responseData = await _sendAndReceive(request.encode());
      final response = ProvisioningResponse.decode(responseData);

      if (!response.isSuccess) {
        throw const ProtocolError('Failed to apply configuration');
      }

      _logger.i('Configuration applied');
    } catch (e) {
      _logger.e('Apply configuration failed: $e');
      if (e is ProvisioningError) rethrow;
      throw ProtocolError('Apply configuration failed: $e');
    }
  }

  /// Poll provisioning status
  Future<ProvisioningStatus> getProvisioningStatus() async {
    _logger.d('Polling provisioning status');

    try {
      final request = ProvisioningRequest(
        endpoint: config.applyEndpoint,
        payload: Uint8List.fromList([0x02]), // Status query
      );

      final responseData = await _sendAndReceive(request.encode());
      final response = ProvisioningResponse.decode(responseData);

      if (!response.isSuccess) {
        return ProvisioningStatus.failed;
      }

      final statusResponse = ProvisioningStatusResponse.decode(response.payload);

      if (statusResponse.isSuccess) {
        return ProvisioningStatus.success;
      } else if (statusResponse.isFailed) {
        return ProvisioningStatus.failed;
      } else {
        return ProvisioningStatus.configApplied;
      }
    } catch (e) {
      _logger.e('Status check failed: $e');
      return ProvisioningStatus.failed;
    }
  }

  /// Send custom data
  Future<void> sendCustomData(Map<String, String> data) async {
    _logger.i('Sending custom data');

    try {
      final customRequest = CustomDataRequest(data: data);
      final payload = _encryptIfSecure(customRequest.encode());

      final request = ProvisioningRequest(
        endpoint: config.customDataEndpoint,
        payload: payload,
      );

      final responseData = await _sendAndReceive(request.encode());
      final response = ProvisioningResponse.decode(responseData);

      if (!response.isSuccess) {
        throw const ProtocolError('Failed to send custom data');
      }

      _logger.i('Custom data sent successfully');
    } catch (e) {
      _logger.e('Custom data failed: $e');
      if (e is ProvisioningError) rethrow;
      throw ProtocolError('Custom data failed: $e');
    }
  }

  /// Send request and wait for response
  Future<Uint8List> _sendAndReceive(
    Uint8List data, {
    Duration? timeout,
  }) async {
    final completer = Completer<Uint8List>();
    StreamSubscription<Uint8List>? subscription;

    subscription = transport.responses.listen(
      (response) {
        if (!completer.isCompleted) {
          completer.complete(response);
        }
        subscription?.cancel();
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
        subscription?.cancel();
      },
    );

    try {
      await transport.send(data);

      return await completer.future.timeout(
        timeout ?? config.operationTimeout,
        onTimeout: () {
          subscription?.cancel();
          throw const TimeoutError('Operation timed out');
        },
      );
    } catch (e) {
      subscription.cancel();
      rethrow;
    }
  }

  /// Encrypt payload if secure session is established
  Uint8List _encryptIfSecure(Uint8List plaintext) {
    if (_isSecureSessionEstablished && _encryption != null) {
      final encrypted = _encryption!.encrypt(plaintext);
      // Prepend IV to ciphertext
      return Uint8List.fromList([...encrypted.iv, ...encrypted.ciphertext]);
    }
    return plaintext;
  }

  /// Decrypt payload if secure session is established
  Uint8List _decryptIfSecure(Uint8List data) {
    if (_isSecureSessionEstablished && _encryption != null) {
      // Extract IV and ciphertext
      final iv = Uint8List.fromList(data.sublist(0, 16));
      final ciphertext = Uint8List.fromList(data.sublist(16));

      final encrypted = EncryptedMessage(ciphertext: ciphertext, iv: iv);
      final decrypted = _encryption!.decrypt(encrypted);

      if (!decrypted.isValid) {
        throw const SecurityError('Decryption failed');
      }

      return decrypted.plaintext;
    }
    return data;
  }

  /// Map protocol auth mode to domain enum
  WiFiAuthMode _mapAuthMode(int authMode) {
    switch (authMode) {
      case 0:
        return WiFiAuthMode.open;
      case 1:
        return WiFiAuthMode.wep;
      case 2:
        return WiFiAuthMode.wpaPsk;
      case 3:
        return WiFiAuthMode.wpa2Psk;
      case 4:
        return WiFiAuthMode.wpaWpa2Psk;
      case 5:
        return WiFiAuthMode.wpa2Enterprise;
      case 6:
        return WiFiAuthMode.wpa3Psk;
      case 7:
        return WiFiAuthMode.wpa2Wpa3Psk;
      default:
        return WiFiAuthMode.open;
    }
  }

  /// Reset protocol state
  void reset() {
    _srpClient = null;
    _encryption = null;
    _isSecureSessionEstablished = false;
  }
}

