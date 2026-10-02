import 'package:flutter/foundation.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../core/dates/year_month.dart';
import '../../net_income/models/net_income_period.dart';
import 'calendar_mode.dart';

/// The days the calendar panel shows, as wall-clock midnights: [start]
/// inclusive, [end] exclusive.
@immutable
class CalendarPeriod {
  const CalendarPeriod._(this.mode, this.start, this.end);

  factory CalendarPeriod.day(DateTime day) =>
      CalendarPeriod._(CalendarMode.day, startOfDay(day), startOfNextDay(day));

  /// The week of [day], starting on [firstDayOfWeek] ([DateTime.monday]…
  /// [DateTime.sunday]).
  factory CalendarPeriod.week(DateTime day, int firstDayOfWeek) {
    final start = weekStart(day, firstDayOfWeek);
    return CalendarPeriod._(
      CalendarMode.week,
      start,
      DateTime(start.year, start.month, start.day + 7),
    );
  }

  factory CalendarPeriod.month(YearMonth month) =>
      CalendarPeriod._(CalendarMode.month, month.start, month.end);

  /// From [a] to [b], both included, whichever comes first.
  factory CalendarPeriod.range(DateTime a, DateTime b) {
    final (first, last) = a.isAfter(b) ? (b, a) : (a, b);
    return CalendarPeriod._(
      CalendarMode.range,
      startOfDay(first),
      startOfNextDay(last),
    );
  }

  final CalendarMode mode;
  final DateTime start;

  /// Exclusive.
  final DateTime end;

  /// Midnight on the first day of [day]'s week.
  static DateTime weekStart(DateTime day, int firstDayOfWeek) => DateTime(
    day.year,
    day.month,
    day.day - (day.weekday - firstDayOfWeek + 7) % 7,
  );

  /// Midnight on the last day included.
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  bool get isSingleDay => startOfNextDay(start) == end;

  bool contains(DateTime day) => !day.isBefore(start) && day.isBefore(end);

  /// The same days on the Net income page: a month stays a month there.
  NetIncomePeriod get netIncomePeriod => mode == CalendarMode.month
      ? NetIncomePeriod.month(YearMonth.of(start))
      : NetIncomePeriod.range(start, lastDay);

  @override
  bool operator ==(Object other) =>
      other is CalendarPeriod &&
      other.mode == mode &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(mode, start, end);
}
