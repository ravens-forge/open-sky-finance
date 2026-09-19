import 'package:flutter/foundation.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/transaction.dart';
import 'assets_account_day.dart';

/// A month of one assets account: money in and out, and its days (newest
/// first). Micro-units in the account's currency.
@immutable
class AssetsAccountMonth {
  const AssetsAccountMonth({
    required this.moneyIn,
    required this.moneyOut,
    required this.days,
  });

  /// [transactions] newest first; [endBalance] = balance at the end of the
  /// month (or of the last day shown).
  factory AssetsAccountMonth.of(
    String assetsAccountId,
    List<Transaction> transactions,
    int endBalance,
  ) {
    var moneyIn = 0;
    var moneyOut = 0;
    var balance = endBalance;
    final days = <AssetsAccountDay>[];
    for (final t in transactions) {
      final day = startOfDay(t.occurredAt);
      if (days.isEmpty || days.last.date != day) {
        days.add(
          AssetsAccountDay(date: day, balance: balance, transactions: []),
        );
      }
      days.last.transactions.add(t);
      final effect = effectOn(t, assetsAccountId);
      balance -= effect;
      if (effect > 0) {
        moneyIn += effect;
      } else {
        moneyOut += effect;
      }
    }
    return AssetsAccountMonth(moneyIn: moneyIn, moneyOut: moneyOut, days: days);
  }

  final int moneyIn;

  /// Zero or negative.
  final int moneyOut;
  final List<AssetsAccountDay> days;
}

/// What [t] adds to (or takes from) [assetsAccountId], in its currency.
int effectOn(Transaction t, String assetsAccountId) {
  if (t.type != TransactionType.transfer) return t.amount.micros;
  if (t.assetsAccountId == assetsAccountId) return -t.amount.micros;
  return t.transfer!.amountReceived ?? t.amount.micros;
}
