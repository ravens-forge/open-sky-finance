import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'balance_sheet_drill_down.g.dart';

/// A date another page asks the Balance sheet to show.
@Riverpod(keepAlive: true)
class BalanceSheetDrillDown extends _$BalanceSheetDrillDown {
  @override
  DateTime? build() => null;

  void show(DateTime asOf) => state = asOf;

  void clear() => state = null;
}
