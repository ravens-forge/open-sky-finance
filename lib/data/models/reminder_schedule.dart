import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/dates/wall_clock.dart';
import '../enums/reminder_frequency.dart';

@immutable
class ReminderSchedule {
  const ReminderSchedule({
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    required this.nextDueAt,
    this.endDate,
    this.remainingOccurrences,
  });

  final ReminderFrequency frequency;

  /// Every [interval] periods, ≥ 1.
  final int interval;

  /// First occurrence; anchors the day of month.
  final DateTime startDate;

  /// `null` = finished.
  final DateTime? nextDueAt;

  /// Last allowed occurrence (inclusive).
  final DateTime? endDate;

  /// Occurrences still to come, the next due one included; `null` = unlimited.
  final int? remainingOccurrences;

  /// The occurrence after [due], whatever the end conditions: [interval]
  /// periods later, on [startDate]'s day of month clamped to the month's last
  /// day (31 Jan → 28 Feb → 31 Mar). `null` for [ReminderFrequency.once].
  DateTime? _after(DateTime due) {
    DateTime at(int year, int month, int day) =>
        DateTime(year, month, day, due.hour, due.minute);
    // Day 0 of the following month is the last day of this one.
    DateTime anchored(int year, int month) => at(
      year,
      month,
      math.min(startDate.day, DateTime(year, month + 1, 0).day),
    );
    return switch (frequency) {
      ReminderFrequency.once => null,
      ReminderFrequency.daily => at(due.year, due.month, due.day + interval),
      ReminderFrequency.weekly => at(
        due.year,
        due.month,
        due.day + 7 * interval,
      ),
      ReminderFrequency.monthly => anchored(due.year, due.month + interval),
      ReminderFrequency.yearly => anchored(due.year + interval, due.month),
    };
  }

  ReminderSchedule _with(DateTime? nextDueAt, int? remainingOccurrences) =>
      ReminderSchedule(
        frequency: frequency,
        interval: interval,
        startDate: startDate,
        nextDueAt: nextDueAt,
        endDate: endDate,
        remainingOccurrences: remainingOccurrences,
      );

  /// This schedule with [nextDueAt] cleared when the end conditions no longer
  /// allow it: no occurrences left, or due after [endDate]'s day.
  ReminderSchedule normalized() {
    final due = nextDueAt;
    final allowed =
        due != null &&
        remainingOccurrences != 0 &&
        (endDate == null || !startOfDay(due).isAfter(endDate!));
    return _with(allowed ? due : null, remainingOccurrences);
  }

  /// This schedule once its next occurrence was recorded or skipped: one
  /// occurrence fewer, due on the following date, or finished.
  ReminderSchedule advanced() {
    final due = nextDueAt;
    if (due == null) return this;
    final remaining = remainingOccurrences;
    return _with(
      _after(due),
      remaining == null ? null : remaining - 1,
    ).normalized();
  }

  /// The occurrences still to come, the next due one first. Endless for a
  /// schedule without end: take what is needed.
  Iterable<DateTime> get upcoming sync* {
    for (var s = this; s.nextDueAt != null; s = s.advanced()) {
      yield s.nextDueAt!;
    }
  }

  /// The occurrences still to come with `from <= due < to`.
  Iterable<DateTime> occurrencesIn(DateTime from, DateTime to) => upcoming
      .takeWhile((due) => due.isBefore(to))
      .where((due) => !due.isBefore(from));
}
