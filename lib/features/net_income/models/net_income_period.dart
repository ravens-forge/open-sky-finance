import 'package:flutter/foundation.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../core/dates/year_month.dart';

enum NetIncomePeriodKind { month, quarter, year, range }

@immutable
class NetIncomePeriod {
  const NetIncomePeriod._(
    this.kind,
    this.start,
    this.end, {
    this.month,
    this.quarter,
    this.year,
  });

  factory NetIncomePeriod.month(YearMonth month) => NetIncomePeriod._(
    NetIncomePeriodKind.month,
    month.start,
    month.end,
    month: month,
  );

  /// [quarter] is 1–4.
  factory NetIncomePeriod.quarter(int year, int quarter) => NetIncomePeriod._(
    NetIncomePeriodKind.quarter,
    DateTime(year, (quarter - 1) * 3 + 1),
    DateTime(year, (quarter - 1) * 3 + 4),
    quarter: quarter,
    year: year,
  );

  factory NetIncomePeriod.year(int year) => NetIncomePeriod._(
    NetIncomePeriodKind.year,
    DateTime(year),
    DateTime(year + 1),
    year: year,
  );

  /// [from] and [to] are the first and last day included.
  factory NetIncomePeriod.range(DateTime from, DateTime to) =>
      NetIncomePeriod._(
        NetIncomePeriodKind.range,
        startOfDay(from),
        startOfNextDay(to),
      );

  final NetIncomePeriodKind kind;
  final DateTime start;

  /// Exclusive.
  final DateTime end;

  final YearMonth? month;
  final int? quarter;
  final int? year;

  static int quarterOf(YearMonth month) => (month.month - 1) ~/ 3 + 1;

  NetIncomePeriod get previous => switch (kind) {
    NetIncomePeriodKind.month => NetIncomePeriod.month(month!.plus(-1)),
    NetIncomePeriodKind.quarter =>
      quarter == 1
          ? NetIncomePeriod.quarter(year! - 1, 4)
          : NetIncomePeriod.quarter(year!, quarter! - 1),
    NetIncomePeriodKind.year => NetIncomePeriod.year(year! - 1),
    NetIncomePeriodKind.range => this,
  };

  NetIncomePeriod get next => switch (kind) {
    NetIncomePeriodKind.month => NetIncomePeriod.month(month!.plus(1)),
    NetIncomePeriodKind.quarter =>
      quarter == 4
          ? NetIncomePeriod.quarter(year! + 1, 1)
          : NetIncomePeriod.quarter(year!, quarter! + 1),
    NetIncomePeriodKind.year => NetIncomePeriod.year(year! + 1),
    NetIncomePeriodKind.range => this,
  };

  @override
  bool operator ==(Object other) =>
      other is NetIncomePeriod &&
      other.kind == kind &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(kind, start, end);
}
