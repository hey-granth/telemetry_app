/// Cryptographic result types
library;

import 'dart:typed_data';

/// Result of SRP handshake
class SrpHandshakeResult {
  const SrpHandshakeResult({
    required this.sessionKey,
    required this.clientPublicKey,
    required this.clientProof,
  });

  final Uint8List sessionKey;
  final Uint8List clientPublicKey;
  final Uint8List clientProof;
}

/// Encrypted message with IV
class EncryptedMessage {
  const EncryptedMessage({
    required this.ciphertext,
    required this.iv,
  });

  final Uint8List ciphertext;
  final Uint8List iv;
}

/// Decrypted and verified message
class DecryptedMessage {
  const DecryptedMessage({
    required this.plaintext,
    required this.isValid,
  });

  final Uint8List plaintext;
  final bool isValid;
}

