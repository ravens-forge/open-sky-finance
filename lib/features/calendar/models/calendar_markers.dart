import 'package:flutter/foundation.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../data/enums/reminder_status.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/reminder.dart';

/// What each day of the grid holds: the types of its transactions (income,
/// expense, transfer dots) and whether a reminder is due (a ring).
@immutable
class CalendarMarkers {
  const CalendarMarkers({required this.transactions, required this.reminders});

  /// [transactions] by day as the repository gives them, plus the days
  /// [from, to) when a running reminder is due.
  factory CalendarMarkers.of(
    Map<DateTime, Set<TransactionType>> transactions,
    List<Reminder> reminders,
    DateTime from,
    DateTime to,
  ) => CalendarMarkers(
    transactions: transactions,
    reminders: {
      for (final r in reminders)
        if (r.status == ReminderStatus.active)
          for (final due in r.schedule.occurrencesIn(from, to)) startOfDay(due),
    },
  );

  static const empty = CalendarMarkers(transactions: {}, reminders: {});

  final Map<DateTime, Set<TransactionType>> transactions;
  final Set<DateTime> reminders;

  /// Income, expense and transfer of [day], in that order; opening balances
  /// have no marker.
  List<TransactionType> typesOn(DateTime day) => [
    for (final type in const [
      TransactionType.income,
      TransactionType.expense,
      TransactionType.transfer,
    ])
      if (transactions[day]?.contains(type) ?? false) type,
  ];

  bool reminderDueOn(DateTime day) => reminders.contains(day);
}
