import 'package:flutter/foundation.dart';

@immutable
class BackupFile {
  const BackupFile({required this.name, required this.bytes});

  /// `open-sky-finance-backup-YYYYMMDD-HHmmss.json`.
  final String name;
  final Uint8List bytes;
}
