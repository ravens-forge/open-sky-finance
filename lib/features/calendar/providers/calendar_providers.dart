import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/now.dart';
import '../../../core/dates/year_month.dart';
import '../../../core/money/currency_converter.dart';
import '../../../data/models/label.dart';
import '../../../data/models/transaction.dart';
import '../../../data/providers.dart';
import '../../balance_sheet/providers/balance_sheet_providers.dart';
import '../../reminders/providers/reminders_providers.dart';
import '../models/calendar_grid.dart';
import '../models/calendar_markers.dart';
import '../models/calendar_period.dart';
import '../models/calendar_reminder_occurrence.dart';

part 'calendar_providers.g.dart';

/// The markers of the six weeks shown for [month].
@riverpod
Stream<CalendarMarkers> calendarMarkers(
  Ref ref,
  YearMonth month,
  int firstDayOfWeek,
) async* {
  final grid = CalendarGrid(month, firstDayOfWeek);
  final reminders = await ref.watch(remindersProvider.future);
  yield* ref
      .watch(transactionsRepositoryProvider)
      .watchCalendarMarkers(grid.start, grid.end)
      .map((days) => CalendarMarkers.of(days, reminders, grid.start, grid.end));
}

/// The period's transactions, newest first.
@riverpod
Stream<List<Transaction>> calendarTransactions(
  Ref ref,
  CalendarPeriod period,
) => ref
    .watch(transactionsRepositoryProvider)
    .watchInRange(period.start, period.end);

/// The labels of the period's transactions, by transaction id.
@riverpod
Stream<Map<String, List<Label>>> calendarTransactionLabels(
  Ref ref,
  CalendarPeriod period,
) => ref
    .watch(labelsRepositoryProvider)
    .watchByTransaction(period.start, period.end);

/// The reminders due in the period, recorded ones included.
@riverpod
Future<List<CalendarReminderOccurrence>> calendarReminders(
  Ref ref,
  CalendarPeriod period,
) async => calendarReminderOccurrences(
  await ref.watch(remindersProvider.future),
  await ref.watch(calendarTransactionsProvider(period).future),
  period,
);

/// The day balances are taken at: the period's last day, or today when the
/// period runs past it (what is scheduled has not happened yet).
@riverpod
DateTime calendarBalanceDate(Ref ref, CalendarPeriod period) {
  final today = ref.watch(todayProvider);
  return period.lastDay.isAfter(today) ? today : period.lastDay;
}

/// Net worth on the Balance sheet as of the end of [asOf], in the main
/// currency.
@riverpod
Future<ConvertedTotal> calendarNetWorth(Ref ref, DateTime asOf) async {
  final sides = await ref.watch(balanceSheetSidesProvider(asOf).future);
  return ConvertedTotal(
    sides.fold(0, (sum, side) => sum + side.total.amount),
    approximate: sides.any((side) => side.total.approximate),
    notIncluded: const {},
  );
}
