import 'package:flutter/foundation.dart';

import '../../../data/models/current_data.dart';
import '../../../services/backup/models/loaded_backup.dart';

/// A checked backup next to the data it would replace.
@immutable
class RestorePreview {
  const RestorePreview({required this.backup, required this.current});

  final LoadedBackup backup;
  final CurrentData current;
}
