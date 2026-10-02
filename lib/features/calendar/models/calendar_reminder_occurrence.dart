import 'package:flutter/foundation.dart';

import '../../../data/enums/reminder_status.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/transaction.dart';
import 'calendar_period.dart';

/// A reminder due in the period: still to come, or [recorded] as a
/// transaction.
@immutable
class CalendarReminderOccurrence {
  const CalendarReminderOccurrence({
    required this.reminder,
    required this.due,
    this.recorded,
  });

  final Reminder reminder;
  final DateTime due;
  final Transaction? recorded;

  /// The occurrence Record and Skip act on.
  bool get isNext => recorded == null && due == reminder.schedule.nextDueAt;
}

/// The occurrences of [period] by due date: those still to come of the
/// running reminders, and those recorded among [transactions] (the period's).
/// Paused reminders have nothing due.
List<CalendarReminderOccurrence> calendarReminderOccurrences(
  List<Reminder> reminders,
  List<Transaction> transactions,
  CalendarPeriod period,
) {
  final byId = {for (final r in reminders) r.id: r};
  return [
    for (final r in reminders)
      if (r.status == ReminderStatus.active)
        for (final due in r.schedule.occurrencesIn(period.start, period.end))
          CalendarReminderOccurrence(reminder: r, due: due),
    for (final t in transactions)
      if (byId[t.reminderId] case final r?)
        CalendarReminderOccurrence(reminder: r, due: t.occurredAt, recorded: t),
  ]..sort((a, b) => a.due.compareTo(b.due));
}
