import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/category_usage.dart';
import '../../../data/providers.dart';
import '../models/category_editor_data.dart';

part 'category_editor_provider.g.dart';

/// Loads the editor once; [id] `null` creates a category or a group.
@riverpod
Future<CategoryEditorData> categoryEditorData(Ref ref, String? id) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  final category = id == null ? null : await repository.findById(id);
  return CategoryEditorData(
    category: category,
    usage: category == null
        ? CategoryUsage.none
        : await repository.usage(category.id),
  );
}
