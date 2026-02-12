/// AES encryption/decryption for secure provisioning
library;

import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'crypto_types.dart';

/// AES-256-CTR encryption service
class AesEncryption {
  AesEncryption({required Uint8List sessionKey})
      : _sessionKey = sessionKey,
        _random = Random.secure() {
    if (sessionKey.length != 32) {
      throw ArgumentError('Session key must be 32 bytes for AES-256');
    }
  }

  final Uint8List _sessionKey;
  final Random _random;

  /// Encrypt plaintext with AES-256-CTR
  EncryptedMessage encrypt(Uint8List plaintext) {
    // Generate random IV
    final iv = _generateIV();

    // Create CTR cipher
    final cipher = _createCipher(iv, forEncryption: true);

    // Encrypt
    final ciphertext = cipher.process(plaintext);

    return EncryptedMessage(
      ciphertext: ciphertext,
      iv: iv,
    );
  }

  /// Decrypt ciphertext with AES-256-CTR
  DecryptedMessage decrypt(EncryptedMessage message) {
    try {
      // Create CTR cipher
      final cipher = _createCipher(message.iv, forEncryption: false);

      // Decrypt
      final plaintext = cipher.process(message.ciphertext);

      return DecryptedMessage(
        plaintext: plaintext,
        isValid: true,
      );
    } catch (e) {
      return DecryptedMessage(
        plaintext: Uint8List(0),
        isValid: false,
      );
    }
  }

  /// Create configured cipher
  StreamCipher _createCipher(Uint8List iv, {required bool forEncryption}) {
    final cipher = SICStreamCipher(AESEngine());

    final params = ParametersWithIV<KeyParameter>(
      KeyParameter(_sessionKey),
      iv,
    );

    cipher.init(forEncryption, params);

    return cipher;
  }

  /// Generate random IV (16 bytes for AES)
  Uint8List _generateIV() {
    final iv = Uint8List(16);
    for (var i = 0; i < iv.length; i++) {
      iv[i] = _random.nextInt(256);
    }
    return iv;
  }
}

/// HMAC-SHA256 for message authentication
class MessageAuthenticator {
  MessageAuthenticator({required Uint8List key}) : _key = key;

  final Uint8List _key;

  /// Compute HMAC-SHA256
  Uint8List computeMAC(Uint8List data) {
    final hmac = HMac(SHA256Digest(), 64);
    hmac.init(KeyParameter(_key));

    return hmac.process(data);
  }

  /// Verify HMAC
  bool verifyMAC(Uint8List data, Uint8List mac) {
    final computed = computeMAC(data);
    return _constantTimeCompare(computed, mac);
  }

  /// Constant-time comparison to prevent timing attacks
  bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

