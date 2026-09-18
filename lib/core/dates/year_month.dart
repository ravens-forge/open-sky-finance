import 'package:flutter/foundation.dart';

@immutable
class YearMonth implements Comparable<YearMonth> {
  YearMonth(int year, int month)
    : this._(DateTime(year, month).year, DateTime(year, month).month);

  const YearMonth._(this.year, this.month);

  YearMonth.of(DateTime date) : this._(date.year, date.month);

  final int year;

  /// 1–12.
  final int month;

  /// Midnight on the 1st: the inclusive start of the month.
  DateTime get start => DateTime(year, month);

  /// Midnight on the 1st of the next month: the exclusive end. Query months as
  /// `start <= date < end`.
  DateTime get end => DateTime(year, month + 1);

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  /// [months] later (or earlier when negative), across years.
  YearMonth plus(int months) => YearMonth(year, month + months);

  bool contains(DateTime date) => date.year == year && date.month == month;

  @override
  int compareTo(YearMonth other) =>
      year != other.year ? year - other.year : month - other.month;

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  /// `2026-09`.
  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}
