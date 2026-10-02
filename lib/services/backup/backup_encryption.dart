import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'models/backup_kdf.dart';
import 'models/backup_key.dart';
import 'models/encrypted_backup.dart';

/// Password-encrypted backups: the plain backup JSON inside a JSON wrapper,
/// with Argon2id for the key and AES-256-GCM for the data. Pure Dart, and
/// slow on purpose (about a second per key), so it runs in a background
/// isolate.
abstract final class BackupEncryption {
  static const format = 'open-sky-finance-backup-encrypted';
  static const _tagLength = 16;

  static Future<BackupKey> deriveKey(
    String password, {
    List<int>? salt,
    BackupKdf kdf = const BackupKdf(),
  }) async {
    final s = salt ?? SecretKeyData.random(length: 16).bytes;
    final key = await Argon2id(
      memory: kdf.memoryKiB,
      iterations: kdf.iterations,
      parallelism: kdf.parallelism,
      hashLength: 32,
    ).deriveKeyFromPassword(password: password, nonce: s);
    return BackupKey(salt: s, bytes: await key.extractBytes(), kdf: kdf);
  }

  /// The wrapper file around [plain], with a new random nonce.
  static Future<Uint8List> encrypt(List<int> plain, BackupKey key) async {
    final box = await AesGcm.with256bits().encrypt(
      plain,
      secretKey: SecretKey(key.bytes),
    );
    return utf8.encode(
      const JsonEncoder.withIndent('  ').convert({
        'format': format,
        'schemaVersion': 1,
        'kdf': {
          'name': 'argon2id',
          'salt': base64.encode(key.salt),
          'memoryKiB': key.kdf.memoryKiB,
          'iterations': key.kdf.iterations,
          'parallelism': key.kdf.parallelism,
        },
        'cipher': {'name': 'aes-256-gcm', 'nonce': base64.encode(box.nonce)},
        'payload': base64.encode([...box.cipherText, ...box.mac.bytes]),
      }),
    );
  }

  /// The wrapper's fields; `null` when they are missing or unknown.
  static EncryptedBackup? read(Map<String, Object?> json) {
    try {
      final kdf = json['kdf']! as Map<String, Object?>;
      final cipher = json['cipher']! as Map<String, Object?>;
      if (json['schemaVersion'] != 1 ||
          kdf['name'] != 'argon2id' ||
          cipher['name'] != 'aes-256-gcm') {
        return null;
      }
      final payload = base64.decode(json['payload']! as String);
      if (payload.length < _tagLength) return null;
      return EncryptedBackup(
        kdf: BackupKdf(
          memoryKiB: kdf['memoryKiB']! as int,
          iterations: kdf['iterations']! as int,
          parallelism: kdf['parallelism']! as int,
        ),
        salt: base64.decode(kdf['salt']! as String),
        nonce: base64.decode(cipher['nonce']! as String),
        payload: payload,
      );
    } on Object {
      return null;
    }
  }

  /// The plain backup inside [file], `null` when [password] is wrong (or
  /// the file was changed).
  static Future<Uint8List?> decrypt(
    EncryptedBackup file,
    String password,
  ) async {
    final key = await deriveKey(password, salt: file.salt, kdf: file.kdf);
    final cut = file.payload.length - _tagLength;
    try {
      final plain = await AesGcm.with256bits().decrypt(
        SecretBox(
          file.payload.sublist(0, cut),
          nonce: file.nonce,
          mac: Mac(file.payload.sublist(cut)),
        ),
        secretKey: SecretKey(key.bytes),
      );
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      return null;
    }
  }
}
