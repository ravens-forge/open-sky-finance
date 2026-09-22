import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/dates/wall_clock.dart';
import '../core/dates/year_month.dart';

part 'now.g.dart';

/// The current local time, refreshed at every new minute, so what depends on
/// it follows the clock (a new day at midnight, a new month). Tests override
/// it with a fixed time. Watch [todayProvider], [tomorrowProvider] or
/// [currentMonthProvider] when only the day or the month matters: they change
/// only when it does.
@Riverpod(keepAlive: true)
DateTime now(Ref ref) {
  final now = DateTime.now();
  final timer = Timer(
    Duration(seconds: 60 - now.second, milliseconds: -now.millisecond),
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);
  return now;
}

/// Midnight at the start of today.
@Riverpod(keepAlive: true)
DateTime today(Ref ref) => ref.watch(nowProvider.select(startOfDay));

/// Midnight tonight: balances "as of today" count transactions before it, so
/// scheduled ones stay out.
@Riverpod(keepAlive: true)
DateTime tomorrow(Ref ref) => ref.watch(nowProvider.select(startOfNextDay));

@Riverpod(keepAlive: true)
YearMonth currentMonth(Ref ref) => ref.watch(nowProvider.select(YearMonth.of));
