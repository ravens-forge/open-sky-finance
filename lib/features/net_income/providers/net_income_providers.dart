import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/main_currency.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../models/net_income_category_group.dart';
import '../models/net_income_period.dart';
import '../models/net_income_summary.dart';

part 'net_income_providers.g.dart';

/// Income, expenses, net income and savings rate of [period], in the main
/// currency.
@riverpod
Stream<NetIncomeSummary> netIncomeSummary(
  Ref ref,
  NetIncomePeriod period,
) async* {
  final converter = await ref.watch(currencyConverterProvider.future);
  yield* ref
      .watch(incomeExpenseRepositoryProvider)
      .watchSummary(period.start, period.end)
      .map((ie) {
        final income = converter.convert(ie.income);
        final net = converter.convert(ie.net);
        return NetIncomeSummary(
          income: income,
          expense: converter.convert(ie.expense),
          net: net,
          savingsRate: income.amount == 0 ? 0 : net.amount / income.amount,
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
  final converter = await ref.watch(currencyConverterProvider.future);
  final groups = await ref.watch(categoryGroupsProvider.future);
  final categories = await ref.watch(categoriesProvider.future);
  final summary = await ref.watch(netIncomeSummaryProvider(period).future);
  final sectionTotal =
      (kind == CategoryKind.income ? summary.income : summary.expense).amount
          .abs();
  yield* ref
      .watch(incomeExpenseRepositoryProvider)
      .watchCategoryTotals(kind, period.start, period.end)
      .map(
        (totals) => groupNetIncomeCategories(
          totals,
          groups,
          categories,
          converter,
          sectionTotal,
        ),
      );
}
