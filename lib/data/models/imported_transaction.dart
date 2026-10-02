import 'package:flutter/foundation.dart';

import '../enums/transaction_type.dart';

/// A transaction read from a CSV or QIF file: everything it points at is
/// named, not referenced, and found or created when it is imported.
@immutable
class ImportedTransaction {
  const ImportedTransaction({
    required this.occurredAt,
    required this.amount,
    this.type,
    this.title = '',
    this.notes = '',
    this.assetsAccount,
    this.toAssetsAccount,
    this.toAmount,
    this.categoryGroup,
    this.category,
    this.labels = const [],
    this.currency,
  });

  /// Local wall-clock time.
  final DateTime occurredAt;

  /// Micro-units with the sign rules of `transactions.amount`; for a
  /// transfer, what leaves [assetsAccount].
  final int amount;

  /// `null`: from the sign, expense when negative, income otherwise.
  final TransactionType? type;
  final String title;
  final String notes;

  /// `null`: the assets account picked for the whole file.
  final String? assetsAccount;

  /// Set on transfers.
  final String? toAssetsAccount;

  /// What arrives when the transfer changes currency.
  final int? toAmount;
  final String? categoryGroup;
  final String? category;
  final List<String> labels;

  /// For an assets account the import creates; the main currency otherwise.
  final String? currency;

  TransactionType get resolvedType =>
      type ?? (amount < 0 ? TransactionType.expense : TransactionType.income);
}
