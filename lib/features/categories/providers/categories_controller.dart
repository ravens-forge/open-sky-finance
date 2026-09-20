import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/reorder_ids.dart';
import '../../../core/result.dart';
import '../../../data/models/category_draft.dart';
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
      _repository.save(draft);

  /// Moves [group]'s item at [from] to [to] within [all] (every category id,
  /// in order). [group] is the groups of a kind, or the categories of one
  /// group.
  Future<void> move(List<String> all, List<String> group, int from, int to) =>
      _repository.reorder(reorderIds(all, group, from, to));

  Future<CategoryUsage> usage(String id) => _repository.usage(id);

  /// Its transactions and reminders move to [reassignTo], or become
  /// uncategorized.
  Future<Result<void, RepositoryDataError>> remove(
    String id, {
    String? reassignTo,
  }) => _repository.remove(id, reassignTo: reassignTo);
}
