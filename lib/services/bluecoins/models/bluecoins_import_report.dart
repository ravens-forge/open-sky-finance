import 'package:flutter/foundation.dart';

import 'bluecoins_note.dart';
import 'bluecoins_skip_reason.dart';

@immutable
class BluecoinsImportReport {
  const BluecoinsImportReport({
    required this.userVersion,
    required this.skipped,
    required this.notes,
  });

  /// The backup's `PRAGMA user_version`.
  final int userVersion;

  /// Only reasons that happened.
  final Map<BluecoinsSkipReason, int> skipped;

  /// Only notes that happened.
  final Map<BluecoinsNote, int> notes;

  int get skippedTotal => skipped.values.fold(0, (sum, n) => sum + n);
}
