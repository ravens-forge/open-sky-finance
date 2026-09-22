import 'package:flutter/foundation.dart' hide Category;

import '../../../core/money/currency_converter.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_group.dart';

@immutable
class NetIncomeCategory {
  const NetIncomeCategory({
    required this.categoryId,
    required this.name,
    required this.total,
    required this.share,
  });

  /// `null` is uncategorized.
  final String? categoryId;

  /// `null` is uncategorized: the widget shows `l10n.categoryNone`.
  final String? name;
  final ConvertedTotal total;

  /// 0–1 of the section total.
  final double share;
}

/// A category group with its total, share and categories, descending by
/// amount.
@immutable
class NetIncomeCategoryGroup {
  const NetIncomeCategoryGroup({
    required this.groupId,
    required this.name,
    required this.total,
    required this.share,
    required this.categories,
  });

  /// `null` is uncategorized.
  final String? groupId;

  /// `null` is uncategorized: the widget shows `l10n.categoryNone`.
  final String? name;
  final ConvertedTotal total;
  final double share;
  final List<NetIncomeCategory> categories;
}

/// Builds the Income or Expenses section from [totals] (group id → category
/// id → currency → amount, as [IncomeExpenseRepository.watchCategoryTotals]
/// returns), descending by amount; shares are of [sectionTotal] (the
/// section's overall converted total, positive).
List<NetIncomeCategoryGroup> groupNetIncomeCategories(
  Map<String?, Map<String?, Map<String, int>>> totals,
  List<CategoryGroup> groups,
  List<Category> categories,
  CurrencyConverter converter,
  int sectionTotal,
) {
  final groupNames = {for (final g in groups) g.id: g.name};
  final categoryNames = {for (final c in categories) c.id: c.name};
  double shareOf(int amount) =>
      sectionTotal == 0 ? 0 : amount.abs() / sectionTotal;

  final result = [
    for (final MapEntry(key: groupId, value: byCategory) in totals.entries)
      _group(
        groupId,
        byCategory,
        groupNames,
        categoryNames,
        converter,
        shareOf,
      ),
  ]..sort((a, b) => b.total.amount.abs().compareTo(a.total.amount.abs()));
  return result;
}

NetIncomeCategoryGroup _group(
  String? groupId,
  Map<String?, Map<String, int>> byCategory,
  Map<String, String> groupNames,
  Map<String, String> categoryNames,
  CurrencyConverter converter,
  double Function(int) shareOf,
) {
  final total = converter.convert(_sumAll(byCategory));
  final categories = [
    for (final MapEntry(key: categoryId, value: byCurrency)
        in byCategory.entries)
      NetIncomeCategory(
        categoryId: categoryId,
        name: categoryId == null ? null : categoryNames[categoryId],
        total: converter.convert(byCurrency),
        share: shareOf(converter.convert(byCurrency).amount),
      ),
  ]..sort((a, b) => b.total.amount.abs().compareTo(a.total.amount.abs()));
  return NetIncomeCategoryGroup(
    groupId: groupId,
    name: groupId == null ? null : groupNames[groupId],
    total: total,
    share: shareOf(total.amount),
    categories: categories,
  );
}

Map<String, int> _sumAll(Map<String?, Map<String, int>> byCategory) {
  final sums = <String, int>{};
  for (final byCurrency in byCategory.values) {
    for (final MapEntry(:key, :value) in byCurrency.entries) {
      sums[key] = (sums[key] ?? 0) + value;
    }
  }
  return sums;
}
