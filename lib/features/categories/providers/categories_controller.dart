import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/reorder_ids.dart';
import '../../../core/result.dart';
import '../../../data/models/category_draft.dart';
import '../../../data/models/category_group_draft.dart';
import '../../../data/models/category_usage.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/categories_repository.dart';
import '../../../data/repositories/repository_data_error.dart';

part 'categories_controller.g.dart';

/// Writes of the Categories screens. Lists update through their streams.
@Riverpod(keepAlive: true)
class CategoriesController extends _$CategoriesController {
  @override
  FutureOr<void> build() {}

  CategoriesRepository get _repository =>
      ref.read(categoriesRepositoryProvider);

  Future<Result<String, RepositoryDataError>> save(CategoryDraft draft) =>
      _repository.saveCategory(draft);

  Future<Result<String, RepositoryDataError>> saveGroup(
    CategoryGroupDraft draft,
  ) => _repository.saveGroup(draft);

  /// Moves the group at [from] to [to] within [all] (every group id, in
  /// order).
  Future<void> moveGroup(List<String> all, int from, int to) =>
      _repository.reorderGroups(reorderIds(all, all, from, to));

  /// Moves [group]'s category at [from] to [to] within [all] (every category
  /// id, in order); the categories of the other groups keep their place.
  Future<void> move(List<String> all, List<String> group, int from, int to) =>
      _repository.reorderCategories(reorderIds(all, group, from, to));

  Future<CategoryUsage> usage(String id) => _repository.usage(id);

  Future<CategoryUsage> groupUsage(String id) => _repository.groupUsage(id);

  /// Its transactions and reminders move to [reassignTo], or become
  /// uncategorized.
  Future<Result<void, RepositoryDataError>> remove(
    String id, {
    String? reassignTo,
  }) => _repository.remove(id, reassignTo: reassignTo);

  Future<Result<void, RepositoryDataError>> removeGroup(String id) =>
      _repository.removeGroup(id);
}
