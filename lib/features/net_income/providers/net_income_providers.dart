import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/report_currency.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../models/net_income_category_group.dart';
import '../models/net_income_period.dart';
import '../models/net_income_summary.dart';

part 'net_income_providers.g.dart';

/// Income, expenses, net income and savings rate of [period], in the report
/// currency.
@riverpod
Stream<NetIncomeSummary> netIncomeSummary(
  Ref ref,
  NetIncomePeriod period,
) async* {
  final currency = await ref.watch(reportCurrencyProvider.future);
  yield* ref
      .watch(incomeExpenseRepositoryProvider)
      .watchSummary(period.start, period.end)
      .map((ie) {
        final income = ie.income[currency] ?? 0;
        final net = ie.net[currency] ?? 0;
        return NetIncomeSummary(
          income: income,
          expense: ie.expense[currency] ?? 0,
          net: net,
          savingsRate: income == 0 ? 0 : net / income,
        );
      });
}

/// The Income or Expenses section of [period]: category groups with their
/// categories, descending by amount.
@riverpod
Stream<List<NetIncomeCategoryGroup>> netIncomeCategories(
  Ref ref,
  NetIncomePeriod period,
  CategoryKind kind,
) async* {
  final currency = await ref.watch(reportCurrencyProvider.future);
  final groups = await ref.watch(categoryGroupsProvider.future);
  final categories = await ref.watch(categoriesProvider.future);
  final summary = await ref.watch(netIncomeSummaryProvider(period).future);
  final sectionTotal =
      (kind == CategoryKind.income ? summary.income : summary.expense).abs();
  yield* ref
      .watch(incomeExpenseRepositoryProvider)
      .watchCategoryTotals(kind, period.start, period.end)
      .map(
        (totals) => groupNetIncomeCategories(
          totals,
          groups,
          categories,
          currency,
          sectionTotal,
        ),
      );
}
