import 'package:flutter/foundation.dart';

import 'bluecoins_import.dart';

@immutable
class LoadedBluecoins {
  const LoadedBluecoins({
    required this.fileName,
    required this.size,
    required this.import,
  });

  final String fileName;

  /// Bytes.
  final int size;
  final BluecoinsImport import;
}
