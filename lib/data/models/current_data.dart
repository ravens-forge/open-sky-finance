import 'package:flutter/foundation.dart';

/// What a restore would replace, next to the backup in its preview.
@immutable
class CurrentData {
  const CurrentData({
    required this.transactions,
    required this.newestTransaction,
    required this.addedSince,
  });

  /// Outside the Trash, opening balances left out.
  final int transactions;

  /// Local wall-clock time of the latest of them, `null` when there is none.
  final DateTime? newestTransaction;

  /// Transactions created after the backup was made: lost by restoring it.
  final int addedSince;
}
