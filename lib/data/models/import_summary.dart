import 'package:flutter/foundation.dart';

/// What an import of transactions added and left out. Counts only: nothing
/// read from the file.
@immutable
class ImportSummary {
  const ImportSummary({
    this.transactions = 0,
    this.duplicates = 0,
    this.invalid = 0,
    this.assetsAccounts = 0,
    this.categories = 0,
    this.labels = 0,
  });

  /// Added.
  final int transactions;

  /// Already in the app (same assets account, date, amount, title and type).
  final int duplicates;

  /// Broke a rule (a transfer into its own assets account, a zero amount,
  /// an opening balance of an assets account that has one…).
  final int invalid;

  /// Created because no existing one had the name.
  final int assetsAccounts;
  final int categories;
  final int labels;
}
