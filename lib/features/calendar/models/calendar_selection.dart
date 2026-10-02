import 'package:flutter/foundation.dart';

import '../../../core/dates/year_month.dart';
import 'calendar_mode.dart';
import 'calendar_period.dart';
import 'calendar_tab.dart';

/// What the calendar shows: the month on the grid, the selected period and
/// the open tab. Each change returns a new selection.
@immutable
class CalendarSelection {
  const CalendarSelection({
    required this.month,
    required this.period,
    this.rangeStart,
    this.tab = CalendarTab.transactions,
  });

  /// Today, as a day.
  factory CalendarSelection.today(DateTime today) => CalendarSelection(
    month: YearMonth.of(today),
    period: CalendarPeriod.day(today),
  );

  /// The month on the grid.
  final YearMonth month;
  final CalendarPeriod period;

  /// Range mode after the first tap: the day it started from, waiting for
  /// the second tap.
  final DateTime? rangeStart;
  final CalendarTab tab;

  CalendarMode get mode => period.mode;

  CalendarSelection _copy({
    YearMonth? month,
    CalendarPeriod? period,
    DateTime? rangeStart,
    CalendarTab? tab,
  }) => CalendarSelection(
    month: month ?? this.month,
    period: period ?? this.period,
    rangeStart: rangeStart,
    tab: tab ?? this.tab,
  );

  /// The same place in [mode]: today when the selection holds it, else its
  /// first day on the grid's month. A range keeps the selected days.
  CalendarSelection withMode(
    CalendarMode mode,
    DateTime today,
    int firstDayOfWeek,
  ) {
    final day = period.contains(today)
        ? today
        : month.contains(period.start)
        ? period.start
        : month.start;
    return _copy(
      period: switch (mode) {
        CalendarMode.day => CalendarPeriod.day(day),
        CalendarMode.week => CalendarPeriod.week(day, firstDayOfWeek),
        CalendarMode.month => CalendarPeriod.month(month),
        CalendarMode.range => CalendarPeriod.range(
          period.start,
          period.lastDay,
        ),
      },
    );
  }

  /// A tap on [day]. In Range, the first tap starts the range and the second
  /// ends it, in either order.
  CalendarSelection tap(DateTime day, int firstDayOfWeek) => switch (mode) {
    CalendarMode.day => _copy(period: CalendarPeriod.day(day)),
    CalendarMode.week => _copy(
      period: CalendarPeriod.week(day, firstDayOfWeek),
    ),
    CalendarMode.month => _copy(
      month: YearMonth.of(day),
      period: CalendarPeriod.month(YearMonth.of(day)),
    ),
    CalendarMode.range => switch (rangeStart) {
      final start? => _copy(period: CalendarPeriod.range(start, day)),
      null => _copy(period: CalendarPeriod.range(day, day), rangeStart: day),
    },
  };

  /// Shows [month] on the grid; in Month mode it is also the selection.
  CalendarSelection showMonth(YearMonth month) => _copy(
    month: month,
    period: mode == CalendarMode.month ? CalendarPeriod.month(month) : period,
    rangeStart: rangeStart,
  );

  /// Today in the current mode, on its month.
  CalendarSelection showToday(DateTime today, int firstDayOfWeek) => _copy(
    month: YearMonth.of(today),
    period: switch (mode) {
      CalendarMode.day => CalendarPeriod.day(today),
      CalendarMode.week => CalendarPeriod.week(today, firstDayOfWeek),
      CalendarMode.month => CalendarPeriod.month(YearMonth.of(today)),
      CalendarMode.range => CalendarPeriod.range(today, today),
    },
  );

  CalendarSelection withTab(CalendarTab tab) =>
      _copy(tab: tab, rangeStart: rangeStart);

  @override
  bool operator ==(Object other) =>
      other is CalendarSelection &&
      other.month == month &&
      other.period == period &&
      other.rangeStart == rangeStart &&
      other.tab == tab;

  @override
  int get hashCode => Object.hash(month, period, rangeStart, tab);
}
