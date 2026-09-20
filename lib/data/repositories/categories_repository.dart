import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/result.dart';
import '../database/app_database.dart';
import '../database/tables/categories_table.dart';
import '../database/tables/category_groups_table.dart';
import '../database/tables/reminders_table.dart';
import '../database/tables/transactions_table.dart';
import '../enums/category_kind.dart';
import '../models/category.dart';
import '../models/category_draft.dart';
import '../models/category_group.dart';
import '../models/category_group_draft.dart';
import '../models/category_usage.dart';
import 'repository_data_error.dart';
import 'valid_name.dart';

part 'categories_repository.g.dart';

@DriftAccessor(
  tables: [
    CategoryGroupsTable,
    CategoriesTable,
    TransactionsTable,
    RemindersTable,
  ],
)
class CategoriesRepository extends DatabaseAccessor<AppDatabase>
    with _$CategoriesRepositoryMixin {
  CategoriesRepository(super.attachedDatabase);

  /// Every group, hidden ones included, in display order.
  Stream<List<CategoryGroup>> watchGroups() =>
      (select(categoryGroupsTable)
            ..orderBy([(g) => OrderingTerm(expression: g.sortOrder)]))
          .map((r) => r.toDomain())
          .watch();

  /// Every category, hidden ones included, in display order.
  Stream<List<Category>> watchCategories() =>
      (select(categoriesTable)
            ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
          .map((r) => r.toDomain())
          .watch();

  Future<CategoryGroup?> findGroupById(String id) => (select(
    categoryGroupsTable,
  )..where((g) => g.id.equals(id))).map((r) => r.toDomain()).getSingleOrNull();

  Future<Category?> findById(String id) => (select(
    categoriesTable,
  )..where((c) => c.id.equals(id))).map((r) => r.toDomain()).getSingleOrNull();

  /// The type of a category, which is the type of its group.
  Future<CategoryKind?> kindOf(String categoryId) async {
    final query = select(categoriesTable).join([
      innerJoin(
        categoryGroupsTable,
        categoryGroupsTable.id.equalsExp(categoriesTable.groupId),
      ),
    ])..where(categoriesTable.id.equals(categoryId));
    final row = await query.getSingleOrNull();
    return row?.readTable(categoryGroupsTable).kind;
  }

  /// Stores [ids] (the groups, or the categories) in this order.
  Future<void> reorderGroups(List<String> ids) => batch((b) {
    for (final (i, id) in ids.indexed) {
      b.update(
        categoryGroupsTable,
        CategoryGroupsTableCompanion(sortOrder: Value(i)),
        where: (g) => g.id.equals(id),
      );
    }
  });

  Future<void> reorderCategories(List<String> ids) => batch((b) {
    for (final (i, id) in ids.indexed) {
      b.update(
        categoriesTable,
        CategoriesTableCompanion(sortOrder: Value(i)),
        where: (c) => c.id.equals(id),
      );
    }
  });

  Future<Result<String, RepositoryDataError>> saveGroup(CategoryGroupDraft d) =>
      transaction(() async {
        final name = validName(d.name);
        if (name == null) return const Err(RepositoryDataError.invalidName);

        final row = CategoryGroupsTableCompanion(
          name: Value(name),
          kind: Value(d.kind),
          isHidden: Value(d.isHidden),
        );
        final id = d.id ?? newId();
        if (d.id == null) {
          final count = await categoryGroupsTable.count().getSingle();
          await into(categoryGroupsTable)
              .insert(row.copyWith(id: Value(id), sortOrder: Value(count)));
          return Ok(id);
        }

        final existing = await findGroupById(id);
        if (existing == null) return const Err(RepositoryDataError.notFound);
        if (existing.kind != d.kind) {
          // The type is what its categories and their transactions are.
          if (await _countCategories(id) > 0 || await _hasTransactions(id)) {
            return const Err(RepositoryDataError.kindLocked);
          }
          // Income is never budgeted.
          if (d.kind == CategoryKind.income) {
            await (update(
              categoryGroupsTable,
            )..where((g) => g.id.equals(id))).write(
              const CategoryGroupsTableCompanion(
                budgetAmount: Value(null),
                budgetPeriod: Value(null),
              ),
            );
          }
        }
        await (update(
          categoryGroupsTable,
        )..where((g) => g.id.equals(id))).write(row);
        return Ok(id);
      });

  Future<Result<String, RepositoryDataError>> saveCategory(CategoryDraft d) =>
      transaction(() async {
        final name = validName(d.name);
        if (name == null) return const Err(RepositoryDataError.invalidName);
        final group = await findGroupById(d.groupId);
        if (group == null) return const Err(RepositoryDataError.notFound);

        final row = CategoriesTableCompanion(
          name: Value(name),
          groupId: Value(d.groupId),
          icon: Value(d.icon),
          color: Value(d.color),
          isHidden: Value(d.isHidden),
        );
        final id = d.id ?? newId();
        if (d.id == null) {
          final count = await categoriesTable.count().getSingle();
          await into(categoriesTable)
              .insert(row.copyWith(id: Value(id), sortOrder: Value(count)));
          return Ok(id);
        }

        final existing = await findById(id);
        if (existing == null) return const Err(RepositoryDataError.notFound);
        if (existing.groupId != d.groupId && await kindOf(id) != group.kind) {
          // Its transactions are of the old type; only a group of the same
          // type can take them.
          return const Err(RepositoryDataError.categoryKindMismatch);
        }
        await (update(
          categoriesTable,
        )..where((c) => c.id.equals(id))).write(row);
        return Ok(id);
      });

  Future<int> _countCategories(String groupId) =>
      (selectOnly(categoriesTable)
            ..addColumns([categoriesTable.id.count()])
            ..where(categoriesTable.groupId.equals(groupId)))
          .map((r) => r.read(categoriesTable.id.count())!)
          .getSingle();

  /// Trashed transactions included: restoring them must not break the type.
  Future<bool> _hasTransactions(String groupId) async =>
      await customSelect(
        'SELECT 1 FROM transactions t JOIN categories c ON c.id = t.category_id '
        'WHERE c.group_id = ? LIMIT 1',
        variables: [Variable(groupId)],
      ).getSingleOrNull() !=
      null;

  /// What uses a category: the editor shows it and the delete confirmation
  /// asks where it all goes.
  Future<CategoryUsage> usage(String id) async {
    final row = await customSelect(
      '''
SELECT
  (SELECT COUNT(*) FROM transactions WHERE category_id = ?1) AS transactions,
  (SELECT COUNT(*) FROM reminders WHERE category_id = ?1) AS reminders,
  (SELECT budget_amount IS NOT NULL FROM categories WHERE id = ?1) AS budget
''',
      variables: [Variable(id)],
    ).getSingle();
    return CategoryUsage(
      transactions: row.read<int>('transactions'),
      reminders: row.read<int>('reminders'),
      categories: 0,
      hasBudget: row.readNullable<int>('budget') == 1,
    );
  }

  /// What a group holds, and whether deleting it is allowed at all.
  Future<CategoryUsage> groupUsage(String id) async {
    final row = await customSelect(
      '''
SELECT
  (SELECT COUNT(*) FROM categories WHERE group_id = ?1) AS categories,
  (SELECT COUNT(*) FROM transactions t JOIN categories c ON c.id = t.category_id
    WHERE c.group_id = ?1) AS transactions,
  (SELECT COUNT(*) FROM reminders r JOIN categories c ON c.id = r.category_id
    WHERE c.group_id = ?1) AS reminders,
  (SELECT budget_amount IS NOT NULL FROM category_groups WHERE id = ?1) AS budget
''',
      variables: [Variable(id)],
    ).getSingle();
    return CategoryUsage(
      transactions: row.read<int>('transactions'),
      reminders: row.read<int>('reminders'),
      categories: row.read<int>('categories'),
      hasBudget: row.readNullable<int>('budget') == 1,
    );
  }

  /// Deletes a category. Its transactions and reminders move to [reassignTo]
  /// (a category of the same type), or become uncategorized. Its budget goes
  /// with it.
  Future<Result<void, RepositoryDataError>> remove(
    String id, {
    String? reassignTo,
  }) => transaction(() async {
    final category = await findById(id);
    if (category == null) return const Err(RepositoryDataError.notFound);
    if (reassignTo != null) {
      if (reassignTo == id) return const Err(RepositoryDataError.notFound);
      final target = await findById(reassignTo);
      if (target == null) return const Err(RepositoryDataError.notFound);
      if (await kindOf(reassignTo) != await kindOf(id)) {
        return const Err(RepositoryDataError.categoryKindMismatch);
      }
      await (update(transactionsTable)..where((t) => t.categoryId.equals(id)))
          .write(TransactionsTableCompanion(categoryId: Value(reassignTo)));
      await (update(remindersTable)..where((r) => r.categoryId.equals(id)))
          .write(RemindersTableCompanion(categoryId: Value(reassignTo)));
    }
    await (delete(categoriesTable)..where((c) => c.id.equals(id))).go();
    return const Ok(null);
  });

  /// Deletes an empty group; one that still holds categories stays.
  Future<Result<void, RepositoryDataError>> removeGroup(String id) =>
      transaction(() async {
        final group = await findGroupById(id);
        if (group == null) return const Err(RepositoryDataError.notFound);
        if (await _countCategories(id) > 0) {
          return const Err(RepositoryDataError.groupHasCategories);
        }
        await (delete(categoryGroupsTable)..where((g) => g.id.equals(id))).go();
        return const Ok(null);
      });
}
