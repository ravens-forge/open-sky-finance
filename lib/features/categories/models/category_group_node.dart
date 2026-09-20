// Flutter's own `Category` annotation would shadow the domain object.
import 'package:flutter/foundation.dart' hide Category;

import '../../../data/enums/category_kind.dart';
import '../../../data/models/category.dart';

/// A category group and the categories inside it, both in display order.
@immutable
class CategoryGroupNode {
  const CategoryGroupNode({required this.group, required this.categories});

  final Category group;
  final List<Category> categories;

  /// A category without its own colour follows its group's.
  int colorOf(Category category) => category.color ?? group.color!;
}

/// The groups of [kind] with their categories, keeping the order of [all]
/// (every category, by sort order). With [includeHidden] false a hidden
/// category is left out, and a hidden group takes its categories with it.
List<CategoryGroupNode> groupCategories(
  List<Category> all,
  CategoryKind kind, {
  bool includeHidden = true,
}) {
  final categories = <String, List<Category>>{};
  for (final category in all) {
    if (category.isGroup || (!includeHidden && category.isHidden)) continue;
    (categories[category.parentId!] ??= []).add(category);
  }
  return [
    for (final group in all)
      if (group.isGroup &&
          group.kind == kind &&
          (includeHidden || !group.isHidden))
        CategoryGroupNode(
          group: group,
          categories: categories[group.id] ?? const [],
        ),
  ];
}
