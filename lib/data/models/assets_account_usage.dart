import 'package:flutter/foundation.dart';

/// What deleting an assets account removes permanently.
@immutable
class AssetsAccountUsage {
  const AssetsAccountUsage({
    required this.transactions,
    required this.trashed,
    required this.reminders,
  });

  /// Transactions touching it (either side of a transfer), trashed ones
  /// included, opening balance excluded.
  final int transactions;

  /// Of [transactions], those in the Trash.
  final int trashed;
  final int reminders;
}
