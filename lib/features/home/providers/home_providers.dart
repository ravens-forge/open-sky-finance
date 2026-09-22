import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/main_currency.dart';
import '../../../core/dates/wall_clock.dart';
import '../../../core/dates/year_month.dart';
import '../../../core/money/currency_converter.dart';
import '../../../data/models/budget_progress.dart';
import '../../../data/models/home_section.dart';
import '../../../data/models/reminder.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/setting_keys.dart';
import '../../categories/providers/categories_providers.dart';
import '../models/budget_slice.dart';
import '../models/budget_summary.dart';
import '../models/cash_flow_month.dart';

part 'home_providers.g.dart';

/// Reminders listed by the "Upcoming reminders" section.
const upcomingRemindersShown = 5;

/// Every section once, in order, with its visibility.
@riverpod
Stream<List<HomeSection>> homeSections(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watchHomeSections();

/// Months shown by the monthly charts: 6 (default) or 12.
@riverpod
Stream<int> homeChartMonths(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.homeChartMonths)
    .map((value) => value == '12' ? 12 : 6);

/// Income and expenses of the chart assets accounts for the last [months]
/// months, the current one last.
@riverpod
Stream<List<CashFlowMonth>> homeCashFlow(Ref ref, int months) async* {
  final converter = await ref.watch(currencyConverterProvider.future);
  final now = YearMonth.of(DateTime.now());
  yield* ref
      .watch(incomeExpenseRepositoryProvider)
      .watchCashFlow(now.plus(1 - months), now.plus(1))
      .map(
        (flow) => [
          for (final MapEntry(key: month, value: totals) in flow.entries)
            CashFlowMonth(
              month,
              income: converter.convert(totals.income).amount,
              expense: converter.convert(totals.expense).amount,
            ),
        ],
      );
}

/// Month-end net worth of the chart assets accounts for the last [months]
/// months; the current month ends today.
@riverpod
Stream<Map<YearMonth, int>> homeNetWorth(Ref ref, int months) async* {
  final converter = await ref.watch(currencyConverterProvider.future);
  final now = YearMonth.of(DateTime.now());
  yield* ref
      .watch(balancesRepositoryProvider)
      .watchNetWorthHistory(
        now.plus(1 - months),
        now,
        before: startOfTomorrow(),
      )
      .map(
        (history) => history.map(
          (month, totals) => MapEntry(month, converter.convert(totals).amount),
        ),
      );
}

/// Net worth of the chart assets accounts today.
@riverpod
Stream<ConvertedTotal> homeNetWorthToday(Ref ref) async* {
  final converter = await ref.watch(currencyConverterProvider.future);
  final now = YearMonth.of(DateTime.now());
  yield* ref
      .watch(balancesRepositoryProvider)
      .watchNetWorthHistory(now, now, before: startOfTomorrow())
      .map((history) => converter.convert(history[now]!));
}

/// Net income of the chart assets accounts this month.
@riverpod
Stream<ConvertedTotal> homeNetIncomeThisMonth(Ref ref) async* {
  final converter = await ref.watch(currencyConverterProvider.future);
  final now = YearMonth.of(DateTime.now());
  yield* ref
      .watch(incomeExpenseRepositoryProvider)
      .watchCashFlow(now, now.plus(1))
      .map((flow) => converter.convert(flow[now]!.net));
}

@riverpod
Stream<List<BudgetProgress>> homeBudgetProgress(Ref ref) => ref
    .watch(budgetsRepositoryProvider)
    .watchProgress(YearMonth.of(DateTime.now()));

/// This month's spending per budget and what is left, in the main currency.
@riverpod
Future<BudgetSummary> homeBudgetSummary(Ref ref) async {
  final progress = await ref.watch(homeBudgetProgressProvider.future);
  final converter = await ref.watch(currencyConverterProvider.future);
  final names = {
    for (final g in await ref.watch(categoryGroupsProvider.future))
      g.id: g.name,
    for (final c in await ref.watch(categoriesProvider.future)) c.id: c.name,
  };
  return BudgetSummary(
    slices: [
      for (final p in progress)
        BudgetSlice(
          name: names[p.budget.targetId] ?? '',
          spent: math.max(0, converter.convert(p.spent).amount),
        ),
    ],
    budgeted: progress.fold(0, (sum, p) => sum + p.budget.amount),
  );
}

/// The next due reminders, overdue first.
@riverpod
Stream<List<Reminder>> homeUpcomingReminders(Ref ref) => ref
    .watch(remindersRepositoryProvider)
    .watchUpcoming(upcomingRemindersShown);
