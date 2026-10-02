import 'package:flutter/foundation.dart';

/// Argon2id costs: written into every encrypted file, so a restore derives
/// the same key whatever the defaults are by then.
@immutable
class BackupKdf {
  const BackupKdf({
    this.memoryKiB = 65536,
    this.iterations = 3,
    this.parallelism = 1,
  });

  final int memoryKiB;
  final int iterations;
  final int parallelism;
}
