import 'package:flutter/foundation.dart';

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

  /// `null` = unlimited.
  final int? remainingOccurrences;
}
