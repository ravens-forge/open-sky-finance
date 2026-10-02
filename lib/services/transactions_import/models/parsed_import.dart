import 'package:flutter/foundation.dart';

import '../../../data/models/imported_transaction.dart';
import 'import_format.dart';

/// The transactions read from a CSV or QIF file, not imported yet.
@immutable
class ParsedImport {
  const ParsedImport({
    required this.format,
    required this.transactions,
    this.unreadable = 0,
  });

  final ImportFormat format;
  final List<ImportedTransaction> transactions;

  /// Rows or entries without a date or an amount that reads as one: left
  /// out.
  final int unreadable;

  /// Some rows name no assets account (a QIF file of one account, a CSV
  /// file without that column): the user picks one for them.
  bool get needsAssetsAccount =>
      transactions.any((t) => t.assetsAccount == null);
}
