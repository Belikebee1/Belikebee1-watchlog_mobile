import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// On-disk envelope for a passphrase-encrypted backup of the app's
/// local state. Carrying server tokens means this thing MUST be
/// encrypted — anyone who can decode it can act as every paired
/// device for every server.
///
/// Wire format (single JSON object, base64-encoded fields):
///   {
///     "v": 1,                                     // schema version
///     "kind": "watchlog_backup",
///     "created_at": "...",                        // for the importer to show
///     "kdf": "pbkdf2_sha256",
///     "kdf_iterations": 600000,
///     "salt": "base64",                           // 16 random bytes
///     "iv":   "base64",                           // 12 random bytes (GCM)
///     "ciphertext": "base64",                     // payload + 16-byte tag
///   }
///
/// The payload itself is the [BackupPayload] JSON we let the user
/// restore. Cipher: AES-GCM-256 with the key derived from the
/// passphrase via PBKDF2-HMAC-SHA256 at 600k iterations — matches
/// current OWASP guidance for SHA256.

const int _kSchemaVersion = 1;
const int _kPbkdfIterations = 600000;
const int _kSaltLen = 16;
const int _kIvLen = 12;

class BackupCodec {
  static final _aes = AesGcm.with256bits();
  static final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _kPbkdfIterations,
    bits: 256,
  );

  /// Encrypt [payload] (any JSON-serializable map) with [passphrase].
  /// Returns the wire-format JSON string ready to write to a file.
  static Future<String> encrypt({
    required Map<String, dynamic> payload,
    required String passphrase,
  }) async {
    if (passphrase.length < 8) {
      throw ArgumentError('Passphrase must be at least 8 characters');
    }
    final salt = _randBytes(_kSaltLen);
    final iv = _randBytes(_kIvLen);
    final secretKey = await _kdf.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    final plaintext = utf8.encode(jsonEncode(payload));
    final box = await _aes.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: iv,
    );
    // Cryptography's SecretBox separates ciphertext + MAC; for the
    // on-disk envelope we concatenate them since AES-GCM tag is
    // exactly 16 bytes and the importer slices accordingly.
    final wire = {
      'v': _kSchemaVersion,
      'kind': 'watchlog_backup',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'kdf': 'pbkdf2_sha256',
      'kdf_iterations': _kPbkdfIterations,
      'salt': base64.encode(salt),
      'iv': base64.encode(iv),
      'ciphertext':
          base64.encode([...box.cipherText, ...box.mac.bytes]),
    };
    return jsonEncode(wire);
  }

  /// Decrypt a wire-format blob. Throws [FormatException] on
  /// schema/version mismatches and [DecryptError] on bad passphrase
  /// (wraps the underlying cryptography exception so callers can
  /// distinguish 'wrong password' from 'corrupted file').
  static Future<Map<String, dynamic>> decrypt({
    required String wire,
    required String passphrase,
  }) async {
    final raw = jsonDecode(wire);
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Not a backup file');
    }
    if (raw['kind'] != 'watchlog_backup') {
      throw const FormatException('Wrong file kind');
    }
    final v = raw['v'];
    if (v is! int || v < 1 || v > _kSchemaVersion) {
      throw FormatException('Unsupported backup version: $v');
    }
    final salt = base64.decode(raw['salt'] as String);
    final iv = base64.decode(raw['iv'] as String);
    final ctTagB64 = raw['ciphertext'] as String;
    final ctTag = base64.decode(ctTagB64);
    if (ctTag.length < 16) {
      throw const FormatException('Ciphertext too short');
    }
    final cipherText = ctTag.sublist(0, ctTag.length - 16);
    final mac = ctTag.sublist(ctTag.length - 16);

    final secretKey = await _kdf.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    try {
      final clear = await _aes.decrypt(
        SecretBox(cipherText, nonce: iv, mac: Mac(mac)),
        secretKey: secretKey,
      );
      final json = jsonDecode(utf8.decode(clear));
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Decoded payload is not an object');
      }
      return json;
    } on SecretBoxAuthenticationError catch (e) {
      throw DecryptError('Wrong passphrase or corrupted file', cause: e);
    }
  }

  static List<int> _randBytes(int n) {
    // cryptography's SecureRandom is sync — pull bytes off it directly.
    return SecretKeyData.random(length: n).bytes;
  }
}

class DecryptError implements Exception {
  final String message;
  final Object? cause;
  DecryptError(this.message, {this.cause});
  @override
  String toString() => 'DecryptError: $message';
}
