import 'package:flutter/foundation.dart';

import '../enums/transaction_type.dart';

/// What the transaction editor saves. [id] `null` creates a transaction.
@immutable
class TransactionDraft {
  const TransactionDraft({
    this.id,
    required this.type,
    required this.occurredAt,
    required this.amount,
    required this.assetsAccountId,
    this.toAssetsAccountId,
    this.toAmount,
    this.categoryId,
    this.title = '',
    this.notes = '',
    this.labelIds = const [],
    this.reminderId,
  });

  final String? id;
  final TransactionType type;
  final DateTime occurredAt;

  /// Micro-units, with the sign rules of `transactions.amount`.
  final int amount;
  final String assetsAccountId;
  final String? toAssetsAccountId;
  final int? toAmount;
  final String? categoryId;
  final String title;
  final String notes;
  final List<String> labelIds;
  final String? reminderId;
}
