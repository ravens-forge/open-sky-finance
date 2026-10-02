import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/net_income_period.dart';

part 'net_income_drill_down.g.dart';

/// A period another page asks Net income to show.
@Riverpod(keepAlive: true)
class NetIncomeDrillDown extends _$NetIncomeDrillDown {
  @override
  NetIncomePeriod? build() => null;

  void show(NetIncomePeriod period) => state = period;

  void clear() => state = null;
}
