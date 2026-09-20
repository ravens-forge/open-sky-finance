// Flutter's own `Category` annotation would shadow the domain object.
import 'package:flutter/foundation.dart' hide Category;

import '../../../data/models/category.dart';
import '../../../data/models/category_usage.dart';

/// What the category and group editors start from. The lists they show
/// (groups, categories of a group) come from the categories stream instead,
/// so they follow writes made while the editor is open.
@immutable
class CategoryEditorData {
  const CategoryEditorData({required this.category, required this.usage});

  /// `null` when creating.
  final Category? category;

  /// [CategoryUsage.none] when creating.
  final CategoryUsage usage;
}
