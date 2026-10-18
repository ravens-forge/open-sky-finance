import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/default_currency.dart';
import '../../../app/report_currency.dart';
import '../../../app/now.dart';
import '../../../core/dates/year_month.dart';
import '../../../data/models/home_section.dart';
import '../../../data/models/reminder.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/setting_keys.dart';
import '../../budgets/providers/budgets_providers.dart';
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

/// Income and expenses of the chart assets accounts in the report currency
/// for the last [months] months, the current one last.
@riverpod
Stream<List<CashFlowMonth>> homeCashFlow(Ref ref, int months) async* {
  final currency = await ref.watch(reportCurrencyProvider.future);
  final now = ref.watch(currentMonthProvider);
  yield* ref
      .watch(incomeExpenseRepositoryProvider)
      .watchCashFlow(now.plus(1 - months), now.plus(1))
      .map(
        (flow) => [
          for (final MapEntry(key: month, value: totals) in flow.entries)
            CashFlowMonth(
              month,
              income: totals.income[currency] ?? 0,
              expense: totals.expense[currency] ?? 0,
            ),
        ],
      );
}

/// Month-end net worth of the chart assets accounts in the report currency
/// for the last [months] months; the current month ends today.
@riverpod
Stream<Map<YearMonth, int>> homeNetWorth(Ref ref, int months) async* {
  final currency = await ref.watch(reportCurrencyProvider.future);
  final now = ref.watch(currentMonthProvider);
  yield* ref
      .watch(balancesRepositoryProvider)
      .watchNetWorthHistory(
        now.plus(1 - months),
        now,
        before: ref.watch(tomorrowProvider),
      )
      .map(
        (history) => history.map(
          (month, totals) => MapEntry(month, totals[currency] ?? 0),
        ),
      );
}

/// Net worth of the chart assets accounts in the report currency today.
@riverpod
Stream<int> homeNetWorthToday(Ref ref) async* {
  final currency = await ref.watch(reportCurrencyProvider.future);
  final now = ref.watch(currentMonthProvider);
  yield* ref
      .watch(balancesRepositoryProvider)
      .watchNetWorthHistory(now, now, before: ref.watch(tomorrowProvider))
      .map((history) => history[now]![currency] ?? 0);
}

/// Net income of the chart assets accounts in the report currency this
/// month.
@riverpod
Stream<int> homeNetIncomeThisMonth(Ref ref) async* {
  final currency = await ref.watch(reportCurrencyProvider.future);
  final now = ref.watch(currentMonthProvider);
  yield* ref
      .watch(incomeExpenseRepositoryProvider)
      .watchCashFlow(now, now.plus(1))
      .map((flow) => flow[now]!.net[currency] ?? 0);
}

/// This month's spending per budget and what is left. Budgets are in the
/// default currency and count only spending in it.
@riverpod
Future<BudgetSummary> homeBudgetSummary(Ref ref) async {
  final progress = await ref.watch(
    budgetProgressProvider(ref.watch(currentMonthProvider)).future,
  );
  final currency = await ref.watch(defaultCurrencyProvider.future);
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
          spent: math.max(0, p.spent[currency] ?? 0),
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
