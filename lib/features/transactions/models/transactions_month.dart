import 'package:flutter/foundation.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/income_expense.dart';
import '../../../data/models/transaction.dart';
import 'transactions_day.dart';

/// A period of the transactions list: the scheduled (future-dated) rows
/// first, then the days, and the income and expenses of the whole period.
///
/// Amounts stay per currency; the screen converts them to the main currency
/// for display.
@immutable
class TransactionsMonth {
  const TransactionsMonth({
    required this.scheduled,
    required this.scheduledNet,
    required this.days,
    required this.totals,
  });

  /// [transactions] newest first; [tomorrow] = midnight tonight, so today's
  /// rows are not scheduled.
  factory TransactionsMonth.of(
    List<Transaction> transactions,
    DateTime tomorrow,
  ) {
    final scheduled = <Transaction>[];
    final scheduledNet = <String, int>{};
    final days = <TransactionsDay>[];
    final totals = IncomeExpense();
    for (final t in transactions) {
      final into = switch (t.type) {
        TransactionType.income => totals.income,
        TransactionType.expense => totals.expense,
        _ => null,
      };
      if (into != null) {
        _add(into, t);
      }
      if (!t.occurredAt.isBefore(tomorrow)) {
        scheduled.add(t);
        if (into != null) _add(scheduledNet, t);
        continue;
      }
      final day = startOfDay(t.occurredAt);
      if (days.isEmpty || days.last.date != day) {
        days.add(TransactionsDay(date: day, transactions: [], net: {}));
      }
      days.last.transactions.add(t);
      if (into != null) _add(days.last.net, t);
    }
    return TransactionsMonth(
      scheduled: scheduled,
      scheduledNet: scheduledNet,
      days: days,
      totals: totals,
    );
  }

  final List<Transaction> scheduled;

  /// Net of [scheduled], per currency.
  final Map<String, int> scheduledNet;
  final List<TransactionsDay> days;
  final IncomeExpense totals;

  bool get isEmpty => scheduled.isEmpty && days.isEmpty;

  static void _add(Map<String, int> into, Transaction t) {
    final currency = t.amount.currency;
    into[currency] = (into[currency] ?? 0) + t.amount.micros;
  }
}
