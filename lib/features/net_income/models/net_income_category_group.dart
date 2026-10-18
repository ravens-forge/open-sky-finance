import 'package:flutter/foundation.dart' hide Category;

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
  final int total;

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
  final int total;
  final double share;
  final List<NetIncomeCategory> categories;
}

/// Builds the Income or Expenses section in [currency] from [totals] (group
/// id → category id → currency → amount, as
/// [IncomeExpenseRepository.watchCategoryTotals] returns), descending by
/// amount; categories without amounts in [currency] are left out, nothing is
/// converted. Shares are of [sectionTotal] (the section's total, positive).
List<NetIncomeCategoryGroup> groupNetIncomeCategories(
  Map<String?, Map<String?, Map<String, int>>> totals,
  List<CategoryGroup> groups,
  List<Category> categories,
  String currency,
  int sectionTotal,
) {
  final groupNames = {for (final g in groups) g.id: g.name};
  final categoryNames = {for (final c in categories) c.id: c.name};
  double shareOf(int amount) =>
      sectionTotal == 0 ? 0 : amount.abs() / sectionTotal;

  final result = [
    for (final MapEntry(key: groupId, value: byCategory) in totals.entries)
      if (byCategory.values.any((c) => c.containsKey(currency)))
        _group(
          groupId,
          byCategory,
          groupNames,
          categoryNames,
          currency,
          shareOf,
        ),
  ]..sort((a, b) => b.total.abs().compareTo(a.total.abs()));
  return result;
}

NetIncomeCategoryGroup _group(
  String? groupId,
  Map<String?, Map<String, int>> byCategory,
  Map<String, String> groupNames,
  Map<String, String> categoryNames,
  String currency,
  double Function(int) shareOf,
) {
  final categories = [
    for (final MapEntry(key: categoryId, value: byCurrency)
        in byCategory.entries)
      if (byCurrency[currency] case final total?)
        NetIncomeCategory(
          categoryId: categoryId,
          name: categoryId == null ? null : categoryNames[categoryId],
          total: total,
          share: shareOf(total),
        ),
  ]..sort((a, b) => b.total.abs().compareTo(a.total.abs()));
  final total = categories.fold(0, (sum, c) => sum + c.total);
  return NetIncomeCategoryGroup(
    groupId: groupId,
    name: groupId == null ? null : groupNames[groupId],
    total: total,
    share: shareOf(total),
    categories: categories,
  );
}
