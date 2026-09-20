import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/category_usage.dart';
import '../../../data/providers.dart';
import '../models/category_editor_data.dart';

part 'category_editor_provider.g.dart';

/// Loads the category editor once; [id] `null` creates one.
@riverpod
Future<CategoryEditorData> categoryEditorData(Ref ref, String? id) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  final category = id == null ? null : await repository.findById(id);
  return CategoryEditorData(
    category: category,
    group: category == null
        ? null
        : await repository.findGroupById(category.groupId),
    usage: category == null
        ? CategoryUsage.none
        : await repository.usage(category.id),
  );
}

/// Loads the group editor once; [id] `null` creates one.
@riverpod
Future<CategoryEditorData> categoryGroupEditorData(Ref ref, String? id) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  final group = id == null ? null : await repository.findGroupById(id);
  return CategoryEditorData(
    category: null,
    group: group,
    usage: group == null
        ? CategoryUsage.none
        : await repository.groupUsage(group.id),
  );
}
