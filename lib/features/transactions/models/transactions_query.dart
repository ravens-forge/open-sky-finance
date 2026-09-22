import 'package:flutter/foundation.dart';

import '../../../core/dates/year_month.dart';
import '../../../data/models/transaction_filter.dart';

@immutable
class TransactionsQuery {
  const TransactionsQuery({required this.month, required this.filter});

  final YearMonth month;
  final TransactionFilter filter;
}
