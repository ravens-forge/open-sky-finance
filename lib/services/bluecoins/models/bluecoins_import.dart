import 'package:flutter/foundation.dart';

import '../../../data/models/app_snapshot.dart';
import 'bluecoins_import_report.dart';

@immutable
class BluecoinsImport {
  const BluecoinsImport({required this.snapshot, required this.report});

  final AppSnapshot snapshot;
  final BluecoinsImportReport report;
}
