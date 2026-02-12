/// SRP6a Client Implementation for Security 2
///
/// Implements the SRP (Secure Remote Password) protocol client side
/// for establishing secure sessions with ESP32 devices.
library;

import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';
import 'crypto_types.dart';

/// SRP6a client for Security 2 provisioning
class SrpClient {
  SrpClient({
    required this.username,
    required this.password,
  }) : _random = Random.secure();

  final String username;
  final String password;
  final Random _random;

  // SRP parameters (3072-bit group from RFC 5054)
  static final BigInt _N = BigInt.parse(
    'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74'
    '020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F1437'
    '4FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED'
    'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3DC2007CB8A163BF05'
    '98DA48361C55D39A69163FA8FD24CF5F83655D23DCA3AD961C62F356208552BB'
    '9ED529077096966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B'
    'E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF695581718'
    '3995497CEA956AE515D2261898FA051015728E5A8AAAC42DAD33170D04507A33'
    'A85521ABDF1CBA64ECFB850458DBEF0A8AEA71575D060C7DB3970F85A6E1E4C7'
    'ABF5AE8CDB0933D71E8C94E04A25619DCEE3D2261AD2EE6BF12FFA06D98A0864'
    'D87602733EC86A64521F2B18177B200CBBE117577A615D6C770988C0BAD946E2'
    '08E24FA074E5AB3143DB5BFCE0FD108E4B82D120A93AD2CAFFFFFFFFFFFFFFFF',
    radix: 16,
  );

  static final BigInt _g = BigInt.from(2);
  static final BigInt _k = _computeK();

  BigInt? _a; // Private ephemeral
  BigInt? _A; // Public ephemeral
  BigInt? _S; // Shared secret
  Uint8List? _sessionKey;

  /// Compute k = H(N | g)
  static BigInt _computeK() {
    final digest = SHA256Digest();
    final nBytes = _bigIntToBytes(_N);
    final gBytes = _bigIntToBytes(_g);

    final input = Uint8List.fromList([...nBytes, ...gBytes]);
    final hash = digest.process(input);

    return _bytesToBigInt(hash);
  }

  /// Generate client public key (A)
  Uint8List generateClientPublic() {
    // Generate random private ephemeral value a
    _a = _generateRandomBigInt(256);

    // A = g^a mod N
    _A = _g.modPow(_a!, _N);

    return _bigIntToBytes(_A!);
  }

  /// Compute session key from server public key
  SrpHandshakeResult computeSessionKey({
    required Uint8List serverPublicKey,
    required Uint8List salt,
  }) {
    final B = _bytesToBigInt(serverPublicKey);

    // Verify B mod N != 0
    if (B % _N == BigInt.zero) {
      throw Exception('Invalid server public key');
    }

    // u = H(A | B)
    final uBytes = _hashBytes([_bigIntToBytes(_A!), serverPublicKey]);
    final u = _bytesToBigInt(uBytes);

    // x = H(salt | H(username | ":" | password))
    final innerHash = _hashString('$username:$password');
    final x = _bytesToBigInt(_hashBytes([salt, innerHash]));

    // S = (B - k * g^x) ^ (a + u * x) mod N
    final gx = _g.modPow(x, _N);
    final kgx = (_k * gx) % _N;
    final diff = (B - kgx) % _N;
    final exp = (_a! + u * x) % (_N - BigInt.one);
    _S = diff.modPow(exp, _N);

    // K = H(S)
    _sessionKey = _hashBytes([_bigIntToBytes(_S!)]);

    // M1 = H(H(N) XOR H(g) | H(username) | salt | A | B | K)
    final clientProof = _computeClientProof(salt, serverPublicKey);

    return SrpHandshakeResult(
      sessionKey: _sessionKey!,
      clientPublicKey: _bigIntToBytes(_A!),
      clientProof: clientProof,
    );
  }

  /// Verify server proof
  bool verifyServerProof(Uint8List serverProof, Uint8List salt, Uint8List serverPublicKey) {
    if (_sessionKey == null || _A == null) {
      return false;
    }

    // M2 = H(A | M1 | K)
    final clientProof = _computeClientProof(salt, serverPublicKey);
    final expectedProof = _hashBytes([
      _bigIntToBytes(_A!),
      clientProof,
      _sessionKey!,
    ]);

    return _constantTimeCompare(serverProof, expectedProof);
  }

  /// Get established session key
  Uint8List? get sessionKey => _sessionKey;

  /// Compute client proof M1
  Uint8List _computeClientProof(Uint8List salt, Uint8List serverPublicKey) {
    final nHash = _hashBytes([_bigIntToBytes(_N)]);
    final gHash = _hashBytes([_bigIntToBytes(_g)]);
    final ngXor = _xorBytes(nHash, gHash);
    final userHash = _hashString(username);

    return _hashBytes([
      ngXor,
      userHash,
      salt,
      _bigIntToBytes(_A!),
      serverPublicKey,
      _sessionKey!,
    ]);
  }

  /// Generate random BigInt of specified bit length
  BigInt _generateRandomBigInt(int bits) {
    final bytes = Uint8List(bits ~/ 8);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return _bytesToBigInt(bytes);
  }

  /// Hash bytes using SHA-256
  Uint8List _hashBytes(List<Uint8List> inputs) {
    final digest = SHA256Digest();
    final combined = Uint8List.fromList(inputs.expand((x) => x).toList());
    return digest.process(combined);
  }

  /// Hash string using SHA-256
  Uint8List _hashString(String input) {
    final digest = SHA256Digest();
    return digest.process(Uint8List.fromList(input.codeUnits));
  }

  /// XOR two byte arrays
  Uint8List _xorBytes(Uint8List a, Uint8List b) {
    final result = Uint8List(a.length);
    for (var i = 0; i < a.length; i++) {
      result[i] = a[i] ^ b[i];
    }
    return result;
  }

  /// Constant-time comparison
  bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Convert BigInt to bytes
  static Uint8List _bigIntToBytes(BigInt value) {
    final hexString = value.toRadixString(16);
    final paddedHex = hexString.length.isOdd ? '0$hexString' : hexString;
    return Uint8List.fromList(hex.decode(paddedHex));
  }

  /// Convert bytes to BigInt
  static BigInt _bytesToBigInt(Uint8List bytes) {
    return BigInt.parse(hex.encode(bytes), radix: 16);
  }
}

