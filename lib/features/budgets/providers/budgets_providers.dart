import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/default_currency.dart';
import '../../../app/now.dart';
import '../../../core/dates/year_month.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/budget_progress.dart';
import '../../../data/providers.dart';
import '../../categories/models/category_group_node.dart';
import '../../categories/providers/categories_providers.dart';
import '../models/budget_editor_data.dart';
import '../models/budget_line.dart';
import '../models/budget_overview.dart';

part 'budgets_providers.g.dart';

/// Every budget with what was spent on it in [month], by currency.
@riverpod
Stream<List<BudgetProgress>> budgetProgress(Ref ref, YearMonth month) =>
    ref.watch(budgetsRepositoryProvider).watchProgress(month);

/// Spending of [month] in expense categories no budget covers, by currency.
@riverpod
Stream<Map<String, int>> budgetUncovered(Ref ref, YearMonth month) =>
    ref.watch(budgetsRepositoryProvider).watchUncovered(month);

/// The Budget page of [month], in the default currency; spending in other
/// currencies is only listed, never converted.
@riverpod
Future<BudgetOverview> budgetOverview(Ref ref, YearMonth month) async {
  final progress = await ref.watch(budgetProgressProvider(month).future);
  final uncovered = await ref.watch(budgetUncoveredProvider(month).future);
  final currency = await ref.watch(defaultCurrencyProvider.future);
  final groups = {
    for (final g in await ref.watch(categoryGroupsProvider.future)) g.id: g,
  };
  final categories = {
    for (final c in await ref.watch(categoriesProvider.future)) c.id: c,
  };

  final notCounted = <String, int>{};
  void count(Map<String, int> spent) {
    for (final MapEntry(key: other, value: micros) in spent.entries) {
      if (other != currency) {
        notCounted[other] = (notCounted[other] ?? 0) + micros;
      }
    }
  }

  count(uncovered);
  final lines = <BudgetLine>[];
  for (final p in progress) {
    final id = p.budget.targetId;
    count(p.spent);
    final category = p.budget.isGroup ? null : categories[id];
    lines.add(
      BudgetLine(
        id: id,
        isGroup: p.budget.isGroup,
        name: (p.budget.isGroup ? groups[id]?.name : category?.name) ?? '',
        icon: category?.icon,
        color: category?.color,
        budget: p.budget.amount,
        spent: math.max(0, p.spent[currency] ?? 0),
      ),
    );
  }
  // Stable, so budgets equally spent keep their own order.
  final order = {for (final (i, line) in lines.indexed) line.id: i};
  lines.sort((a, b) {
    final byRisk = b.ratio.compareTo(a.ratio);
    return byRisk != 0 ? byRisk : order[a.id]! - order[b.id]!;
  });
  return BudgetOverview(
    lines: lines,
    notBudgeted: uncovered[currency] ?? 0,
    notCounted: {
      for (final MapEntry(:key, :value) in notCounted.entries)
        if (value > 0) key: value,
    },
    currency: currency,
  );
}

/// What Edit budgets starts from: read once, so typing is never overwritten.
@riverpod
Future<BudgetEditorData> budgetEditorData(Ref ref) async {
  final month = ref.watch(currentMonthProvider);
  final currency = await ref.watch(defaultCurrencyProvider.future);
  final totals = await ref
      .watch(incomeExpenseRepositoryProvider)
      .watchCategoryTotals(CategoryKind.expense, month.start, month.end)
      .first;
  final budgets = await ref.watch(budgetsRepositoryProvider).watchAll().first;
  return BudgetEditorData(
    groups: groupCategories(
      await ref.watch(categoryGroupsProvider.future),
      await ref.watch(categoriesProvider.future),
      CategoryKind.expense,
    ),
    budgets: {for (final b in budgets) b.targetId: b.amount},
    spent: {
      for (final categories in totals.values)
        for (final MapEntry(key: id, value: byCurrency) in categories.entries)
          ?id: math.max(0, -(byCurrency[currency] ?? 0)),
    },
    month: month,
    currency: currency,
  );
}
