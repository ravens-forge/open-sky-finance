import 'package:flutter/foundation.dart';

import '../../../data/models/transaction.dart';

/// One day of an assets account's transactions and its balance at the end of it.
@immutable
class AssetsAccountDay {
  const AssetsAccountDay({
    required this.date,
    required this.balance,
    required this.transactions,
  });

  /// Midnight.
  final DateTime date;
  final int balance;

  /// Newest first.
  final List<Transaction> transactions;
}
