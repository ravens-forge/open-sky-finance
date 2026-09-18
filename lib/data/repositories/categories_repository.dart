import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/result.dart';
import '../database/app_database.dart';
import '../database/tables/categories_table.dart';
import '../database/tables/transactions_table.dart';
import '../enums/category_kind.dart';
import '../models/category.dart';
import 'repository_data_error.dart';
import 'valid_name.dart';
import '../models/category_draft.dart';

part 'categories_repository.g.dart';

@DriftAccessor(tables: [CategoriesTable, TransactionsTable])
class CategoriesRepository extends DatabaseAccessor<AppDatabase>
    with _$CategoriesRepositoryMixin {
  CategoriesRepository(super.attachedDatabase);

  /// Groups and subcategories of [kind], in display order.
  Stream<List<Category>> watchByKind(CategoryKind kind) =>
      (select(categoriesTable)
            ..where((c) => c.kind.equalsValue(kind))
            ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
          .map((r) => r.toDomain())
          .watch();

  Future<Category?> findById(String id) => (select(
    categoriesTable,
  )..where((c) => c.id.equals(id))).map((r) => r.toDomain()).getSingleOrNull();

  Future<bool> _hasSubcategories(String id) async =>
      await (select(categoriesTable)
            ..where((c) => c.parentId.equals(id))
            ..limit(1))
          .getSingleOrNull() !=
      null;

  /// Trashed transactions included: restoring them must not break the kind rule.
  Future<bool> _hasTransactions(String id) async =>
      await (select(transactionsTable)
            ..where((t) => t.categoryId.equals(id))
            ..limit(1))
          .getSingleOrNull() !=
      null;

  Future<Result<String, RepositoryDataError>> save(CategoryDraft d) =>
      transaction(() async {
        final name = validName(d.name);
        if (name == null) return const Err(RepositoryDataError.invalidName);
        if (d.parentId == null && d.color == null) {
          return const Err(RepositoryDataError.colorRequired);
        }
        if (d.parentId != null) {
          final parent = await findById(d.parentId!);
          if (parent == null) return const Err(RepositoryDataError.notFound);
          if (parent.parentId != null || parent.id == d.id) {
            return const Err(RepositoryDataError.parentNotGroup);
          }
          if (parent.kind != d.kind) {
            return const Err(RepositoryDataError.categoryKindMismatch);
          }
        }

        final row = CategoriesTableCompanion(
          name: Value(name),
          kind: Value(d.kind),
          parentId: Value(d.parentId),
          icon: Value(d.icon),
          color: Value(d.color),
          isHidden: Value(d.isHidden),
        );

        final id = d.id ?? newId();
        if (d.id == null) {
          final count = await categoriesTable.count().getSingle();
          await into(categoriesTable)
              .insert(row.copyWith(id: Value(id), sortOrder: Value(count)));
        } else {
          final existing = await findById(id);
          if (existing == null) return const Err(RepositoryDataError.notFound);
          final hasSubcategories = await _hasSubcategories(id);
          if (d.parentId != null && hasSubcategories) {
            return const Err(RepositoryDataError.groupHasSubcategories);
          }
          if (existing.kind != d.kind &&
              (hasSubcategories || await _hasTransactions(id))) {
            return const Err(RepositoryDataError.kindLocked);
          }
          await (update(
            categoriesTable,
          )..where((c) => c.id.equals(id))).write(row);
        }
        return Ok(id);
      });

  /// Deletes a category, or a group without subcategories. Its transactions
  /// move to [reassignTo] (same kind), or become uncategorized.
  Future<Result<void, RepositoryDataError>> remove(
    String id, {
    String? reassignTo,
  }) => transaction(() async {
    final category = await findById(id);
    if (category == null) return const Err(RepositoryDataError.notFound);
    if (await _hasSubcategories(id)) {
      return const Err(RepositoryDataError.groupHasSubcategories);
    }
    if (reassignTo != null) {
      final target = await findById(reassignTo);
      if (target == null || target.id == id) {
        return const Err(RepositoryDataError.notFound);
      }
      if (target.kind != category.kind) {
        return const Err(RepositoryDataError.categoryKindMismatch);
      }
      await (update(transactionsTable)..where((t) => t.categoryId.equals(id)))
          .write(TransactionsTableCompanion(categoryId: Value(reassignTo)));
    }
    await (delete(categoriesTable)..where((c) => c.id.equals(id))).go();
    return const Ok(null);
  });
}
