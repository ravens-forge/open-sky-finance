import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'backup_kdf.dart';

/// The key backups are encrypted with, derived from the user's password. It
/// stays on the device (whoever can read it can read the database anyway);
/// the password itself is never stored.
@immutable
class BackupKey {
  const BackupKey({required this.salt, required this.bytes, required this.kdf});

  final List<int> salt;

  /// 32 bytes for AES-256.
  final List<int> bytes;
  final BackupKdf kdf;

  String toJson() => jsonEncode({
    'salt': base64.encode(salt),
    'key': base64.encode(bytes),
    'memoryKiB': kdf.memoryKiB,
    'iterations': kdf.iterations,
    'parallelism': kdf.parallelism,
  });

  /// `null` when [text] is missing or not one of ours.
  static BackupKey? tryParse(String? text) {
    if (text == null) return null;
    try {
      final json = jsonDecode(text) as Map<String, Object?>;
      return BackupKey(
        salt: base64.decode(json['salt']! as String),
        bytes: base64.decode(json['key']! as String),
        kdf: BackupKdf(
          memoryKiB: json['memoryKiB']! as int,
          iterations: json['iterations']! as int,
          parallelism: json['parallelism']! as int,
        ),
      );
    } on Object {
      return null;
    }
  }
}
