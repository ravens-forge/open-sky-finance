import 'package:flutter/foundation.dart';

import '../../../services/backup/models/backup_destination.dart';

@immutable
class LastBackup {
  const LastBackup({required this.at, this.destination, this.size});

  /// Local time.
  final DateTime at;
  final BackupDestination? destination;

  /// Bytes.
  final int? size;
}
