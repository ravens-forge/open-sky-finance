import 'package:flutter/foundation.dart';

import '../../../services/transactions_import/models/parsed_import.dart';

/// A CSV or QIF file read and compared with the current data.
@immutable
class TransactionsImportPreview {
  const TransactionsImportPreview({
    required this.fileName,
    required this.size,
    required this.parsed,
    required this.newAssetsAccounts,
    required this.defaultAssetsAccountId,
  });

  final String fileName;

  /// Bytes.
  final int size;
  final ParsedImport parsed;

  /// Assets accounts the file names that the app does not have yet.
  final int newAssetsAccounts;

  /// Where the rows without an assets account go unless another one is
  /// picked: the first favorite, else the first assets account.
  final String? defaultAssetsAccountId;

  DateTime get first => parsed.transactions
      .map((t) => t.occurredAt)
      .reduce((a, b) => a.isBefore(b) ? a : b);

  DateTime get last => parsed.transactions
      .map((t) => t.occurredAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
}
