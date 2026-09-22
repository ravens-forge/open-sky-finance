import 'package:flutter/foundation.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../data/models/transaction.dart';

@immutable
class TrashDay {
  const TrashDay({required this.date, required this.transactions});

  /// [transactions] trashed, latest deletion first.
  static List<TrashDay> groupsOf(List<Transaction> transactions) {
    final days = <TrashDay>[];
    for (final t in transactions) {
      final day = startOfDay(t.deletedAt!.toLocal());
      if (days.isEmpty || days.last.date != day) {
        days.add(TrashDay(date: day, transactions: []));
      }
      days.last.transactions.add(t);
    }
    return days;
  }

  /// Midnight, local.
  final DateTime date;
  final List<Transaction> transactions;
}
