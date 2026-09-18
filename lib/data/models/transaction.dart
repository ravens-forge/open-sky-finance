import 'package:flutter/foundation.dart';

import '../enums/transaction_type.dart';
import 'money.dart';
import 'timestamps.dart';
import 'transfer_destination.dart';

@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.title,
    required this.amount,
    required this.assetsAccountId,
    required this.transfer,
    required this.categoryId,
    required this.notes,
    required this.reminderId,
    required this.deletedAt,
    required this.timestamps,
  });

  final String id;
  final TransactionType type;

  /// Local wall-clock time, no time zone.
  final DateTime occurredAt;
  final String title;

  /// In the currency of [assetsAccountId]. Signed effect on it, except
  /// transfers: the positive amount leaving it.
  final Money amount;
  final String assetsAccountId;

  /// Set only on transfers.
  final TransferDestination? transfer;
  final String? categoryId;
  final String notes;

  /// Set when recorded from a reminder occurrence.
  final String? reminderId;

  /// UTC. Not null = in the Trash.
  final DateTime? deletedAt;
  final Timestamps timestamps;
}
