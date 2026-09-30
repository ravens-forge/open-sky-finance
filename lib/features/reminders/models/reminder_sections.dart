import 'package:flutter/foundation.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../data/models/reminder.dart';

/// Days ahead listed under "Next 30 days".
const reminderHorizonDays = 30;

/// The active reminders as the page lists them, each section next due first.
@immutable
class ReminderSections {
  const ReminderSections({
    required this.overdue,
    required this.next,
    required this.later,
  });

  /// Splits [active] (next due first) around [today]: due today or before and
  /// waiting for Record or Skip, due within [reminderHorizonDays], and the
  /// rest. An automatic reminder is never overdue: it records itself.
  factory ReminderSections.of(List<Reminder> active, DateTime today) {
    final overdue = <Reminder>[];
    final next = <Reminder>[];
    final later = <Reminder>[];
    for (final reminder in active) {
      final days = daysBetween(today, reminder.schedule.nextDueAt!);
      (days <= 0 && !reminder.autoPost
              ? overdue
              : days <= reminderHorizonDays
              ? next
              : later)
          .add(reminder);
    }
    return ReminderSections(overdue: overdue, next: next, later: later);
  }

  final List<Reminder> overdue;
  final List<Reminder> next;
  final List<Reminder> later;
}
