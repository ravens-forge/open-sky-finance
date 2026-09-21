import 'package:flutter/foundation.dart';

import '../../../data/models/transaction.dart';

@immutable
class TransactionsDay {
  const TransactionsDay({
    required this.date,
    required this.transactions,
    required this.net,
  });

  /// Midnight, local.
  final DateTime date;
  final List<Transaction> transactions;
  final Map<String, int> net;
}
