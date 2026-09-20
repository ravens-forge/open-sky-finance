import 'package:flutter/foundation.dart';

import '../enums/category_kind.dart';

/// A group of categories. It carries the type and nothing to look at: it is
/// drawn in the colour of its [kind], so it has no icon and no colour of its
/// own. Its budget, when it has one, is read through `BudgetsRepository`.
@immutable
class CategoryGroup {
  const CategoryGroup({
    required this.id,
    required this.name,
    required this.kind,
    required this.isHidden,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final CategoryKind kind;

  /// Hides the group and its categories from the pickers.
  final bool isHidden;
  final int sortOrder;
}
