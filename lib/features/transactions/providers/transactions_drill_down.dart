import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dates/year_month.dart';
import '../../../data/models/transaction_filter.dart';
import '../models/transactions_query.dart';

part 'transactions_drill_down.g.dart';

@Riverpod(keepAlive: true)
class TransactionsDrillDown extends _$TransactionsDrillDown {
  @override
  TransactionsQuery? build() => null;

  void show(YearMonth month, TransactionFilter filter) =>
      state = TransactionsQuery(month: month, filter: filter);

  void clear() => state = null;
}
