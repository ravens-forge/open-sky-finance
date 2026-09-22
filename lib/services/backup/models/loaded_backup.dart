import 'package:flutter/foundation.dart';

import '../../../data/models/app_snapshot.dart';

@immutable
class LoadedBackup {
  const LoadedBackup({
    required this.fileName,
    required this.size,
    required this.snapshot,
  });

  final String fileName;

  /// Bytes.
  final int size;
  final AppSnapshot snapshot;
}
