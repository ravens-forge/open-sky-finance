import 'package:flutter/foundation.dart';

import 'backup_kdf.dart';

/// An encrypted backup file, read but not yet unlocked.
@immutable
class EncryptedBackup {
  const EncryptedBackup({
    required this.kdf,
    required this.salt,
    required this.nonce,
    required this.payload,
  });

  final BackupKdf kdf;
  final List<int> salt;
  final List<int> nonce;

  /// The AES-256-GCM ciphertext of the plain backup with its 16-byte tag
  /// appended.
  final List<int> payload;
}
