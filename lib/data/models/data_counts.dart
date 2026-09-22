import 'package:flutter/foundation.dart';

/// How much the user has stored, shown before and after erasing all data.
@immutable
class DataCounts {
  const DataCounts({
    required this.assetsAccounts,
    required this.transactions,
    required this.reminders,
    required this.budgets,
    required this.labels,
    required this.categories,
    required this.trashed,
  });

  final int assetsAccounts;

  /// Outside the Trash, opening balances left out.
  final int transactions;
  final int reminders;

  /// Group and category budgets.
  final int budgets;
  final int labels;
  final int categories;

  /// Transactions in the Trash.
  final int trashed;
}
