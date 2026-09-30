import 'package:intl/intl.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../core/l10n.dart';
import '../../../data/enums/reminder_frequency.dart';
import '../../../data/enums/reminder_status.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/reminder_schedule.dart';
import 'reminder_sections.dart';

/// "Monthly", "Every 2 months", "Once".
String reminderFrequencyLabel(
  ReminderFrequency frequency,
  int interval,
  AppLocalizations l10n,
) => switch (frequency) {
  ReminderFrequency.once => l10n.reminderFrequencyOnce,
  ReminderFrequency.daily => l10n.reminderEveryDays(interval),
  ReminderFrequency.weekly => l10n.reminderEveryWeeks(interval),
  ReminderFrequency.monthly => l10n.reminderEveryMonths(interval),
  ReminderFrequency.yearly => l10n.reminderEveryYears(interval),
};

/// "1 month", "2 weeks": the value of the interval stepper.
String reminderIntervalLabel(
  ReminderFrequency frequency,
  int interval,
  AppLocalizations l10n,
) => switch (frequency) {
  ReminderFrequency.once => '',
  ReminderFrequency.daily => l10n.reminderIntervalDays(interval),
  ReminderFrequency.weekly => l10n.reminderIntervalWeeks(interval),
  ReminderFrequency.monthly => l10n.reminderIntervalMonths(interval),
  ReminderFrequency.yearly => l10n.reminderIntervalYears(interval),
};

/// "Monthly · never ends", "Every 2 weeks · until Dec 25, 2026",
/// "Monthly · 3 more times".
String reminderScheduleSummary(
  ReminderSchedule schedule,
  AppLocalizations l10n,
) {
  final frequency = reminderFrequencyLabel(
    schedule.frequency,
    schedule.interval,
    l10n,
  );
  if (schedule.frequency == ReminderFrequency.once) return frequency;
  return l10n.reminderDetails(frequency, switch (schedule) {
    ReminderSchedule(:final endDate?) => l10n.reminderEndsOn(
      DateFormat.yMMMd(l10n.localeName).format(endDate),
    ),
    ReminderSchedule(:final remainingOccurrences?) => l10n.reminderTimesLeft(
      remainingOccurrences,
    ),
    _ => l10n.reminderNeverEnds,
  });
}

/// A short date, with the year when it is not the one of [today].
String reminderDate(DateTime date, DateTime today, AppLocalizations l10n) =>
    (date.year == today.year
            ? DateFormat.MMMd(l10n.localeName)
            : DateFormat.yMMMd(l10n.localeName))
        .format(date);

/// When [reminder] is due, seen from [today]: "Was due Sep 15", "Due today",
/// "Sep 25 · in 8 days", "Nov 15" past the 30 days, or "Finished". A paused
/// reminder only shows its date: nothing is due while paused.
String reminderDueText(
  Reminder reminder,
  DateTime today,
  AppLocalizations l10n,
) {
  final due = reminder.schedule.nextDueAt;
  if (due == null) return l10n.reminderFinished;
  final date = reminderDate(due, today, l10n);
  if (reminder.status == ReminderStatus.paused) return date;
  final days = daysBetween(today, due);
  return switch (days) {
    < 0 => l10n.reminderWasDue(date),
    0 => l10n.reminderDueToday,
    <= reminderHorizonDays => l10n.transactionSubtitleDated(
      date,
      l10n.reminderInDays(days),
    ),
    _ => date,
  };
}

/// Whether [reminder] is running and due today or before.
bool reminderIsDue(Reminder reminder, DateTime today) =>
    reminder.status == ReminderStatus.active &&
    daysBetween(today, reminder.schedule.nextDueAt!) <= 0;
