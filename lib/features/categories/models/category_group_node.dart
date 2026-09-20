// Flutter's own `Category` annotation would shadow the domain object.
import 'package:flutter/foundation.dart' hide Category;

import '../../../data/enums/category_kind.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_group.dart';

/// A group and the categories inside it, both in display order.
@immutable
class CategoryGroupNode {
  const CategoryGroupNode({required this.group, required this.categories});

  final CategoryGroup group;
  final List<Category> categories;
}

/// The groups of [kind] with their categories, keeping the order of [groups]
/// and [categories] (every one, by sort order). With [includeHidden] false a
/// hidden category is left out, and a hidden group takes its categories with
/// it.
List<CategoryGroupNode> groupCategories(
  List<CategoryGroup> groups,
  List<Category> categories,
  CategoryKind kind, {
  bool includeHidden = true,
}) {
  final byGroup = <String, List<Category>>{};
  for (final category in categories) {
    if (!includeHidden && category.isHidden) continue;
    (byGroup[category.groupId] ??= []).add(category);
  }
  return [
    for (final group in groups)
      if (group.kind == kind && (includeHidden || !group.isHidden))
        CategoryGroupNode(
          group: group,
          categories: byGroup[group.id] ?? const [],
        ),
  ];
}
