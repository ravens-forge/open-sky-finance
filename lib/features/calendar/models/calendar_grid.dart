import 'package:flutter/foundation.dart';

import '../../../core/dates/year_month.dart';
import 'calendar_period.dart';

/// The six weeks shown for [month]: from the start of the week holding the
/// 1st, so every month fits whatever day it starts on.
@immutable
class CalendarGrid {
  CalendarGrid(this.month, int firstDayOfWeek)
    : start = CalendarPeriod.weekStart(month.start, firstDayOfWeek);

  static const weeks = 6;

  final YearMonth month;

  /// Midnight on the first day shown.
  final DateTime start;

  /// Exclusive.
  DateTime get end => DateTime(start.year, start.month, start.day + weeks * 7);

  List<DateTime> get days => [
    for (var i = 0; i < weeks * 7; i++)
      DateTime(start.year, start.month, start.day + i),
  ];
}
