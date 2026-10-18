import 'package:flutter/foundation.dart';

import '../../../core/dates/wall_clock.dart';
import 'balance_sheet_compare_kind.dart';

/// The date the Balance sheet compares with: one that follows the "As of"
/// date, a picked one, or none.
@immutable
class BalanceSheetComparison {
  const BalanceSheetComparison(this.kind, [this.picked]);

  static const initial = BalanceSheetComparison(
    BalanceSheetCompareKind.sameDayLastMonth,
  );

  /// Reads a stored value: a kind's name, or `date:yyyy-MM-dd` for a picked
  /// date. Anything else is [initial].
  factory BalanceSheetComparison.decode(String? value) {
    if (value != null && value.startsWith('date:')) {
      final date = DateTime.tryParse(value.substring(5));
      if (date != null) {
        return BalanceSheetComparison(
          BalanceSheetCompareKind.pickedDate,
          startOfDay(date),
        );
      }
    }
    return BalanceSheetCompareKind.values
            .where((k) => k != BalanceSheetCompareKind.pickedDate)
            .where((k) => k.name == value)
            .map(BalanceSheetComparison.new)
            .firstOrNull ??
        initial;
  }

  final BalanceSheetCompareKind kind;

  /// Set only for [BalanceSheetCompareKind.pickedDate].
  final DateTime? picked;

  String encode() => switch (picked) {
    final date? => 'date:${formatWallClock(date).substring(0, 10)}',
    null => kind.name,
  };

  /// The day compared with when the sheet is as of [asOf]; `null` for none.
  /// A day the month lacks falls back to its last day (Mar 31 → Feb 28).
  DateTime? dateFor(DateTime asOf) => switch (kind) {
    BalanceSheetCompareKind.sameDayLastMonth => _clamped(
      asOf.year,
      asOf.month - 1,
      asOf.day,
    ),
    BalanceSheetCompareKind.endOfLastMonth => DateTime(
      asOf.year,
      asOf.month,
      0,
    ),
    BalanceSheetCompareKind.sameDayLastYear => _clamped(
      asOf.year - 1,
      asOf.month,
      asOf.day,
    ),
    BalanceSheetCompareKind.endOfLastYear => DateTime(asOf.year - 1, 12, 31),
    BalanceSheetCompareKind.pickedDate => picked,
    BalanceSheetCompareKind.none => null,
  };

  static DateTime _clamped(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > last ? last : day);
  }

  @override
  bool operator ==(Object other) =>
      other is BalanceSheetComparison &&
      other.kind == kind &&
      other.picked == picked;

  @override
  int get hashCode => Object.hash(kind, picked);
}
