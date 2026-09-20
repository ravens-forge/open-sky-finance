import 'package:drift/drift.dart';

import '../../core/dates/year_month.dart';
import '../../core/result.dart';
import '../database/app_database.dart';
import '../database/tables/assets_accounts_table.dart';
import '../database/tables/categories_table.dart';
import '../database/tables/category_groups_table.dart';
import '../database/tables/transactions_table.dart';
import '../enums/budget_period.dart';
import '../enums/category_kind.dart';
import '../models/budget.dart';
import '../models/budget_progress.dart';
import 'report_sql.dart';
import 'repository_data_error.dart';

part 'budgets_repository.g.dart';

/// Budgets live on the group or the category they cap, never in a table of
/// their own.
@DriftAccessor(
  tables: [
    CategoryGroupsTable,
    CategoriesTable,
    AssetsAccountsTable,
    TransactionsTable,
  ],
)
class BudgetsRepository extends DatabaseAccessor<AppDatabase>
    with _$BudgetsRepositoryMixin {
  BudgetsRepository(super.attachedDatabase);

  Stream<List<Budget>> watchAll() => customSelect(
    '''
SELECT id, 1 AS is_group, budget_amount AS amount, budget_period AS period,
  budget_rollover AS rollover, sort_order
FROM category_groups WHERE budget_amount IS NOT NULL
UNION ALL
SELECT id, 0, budget_amount, budget_period, budget_rollover, sort_order
FROM categories WHERE budget_amount IS NOT NULL
ORDER BY is_group DESC, sort_order''',
    readsFrom: {categoryGroupsTable, categoriesTable},
  ).watch().map((rows) => [for (final r in rows) _budget(r)]);

  Budget _budget(QueryRow r) => Budget(
    targetId: r.read<String>('id'),
    isGroup: r.read<int>('is_group') == 1,
    amount: r.read<int>('amount'),
    period: BudgetPeriod.values.byName(r.read<String>('period')),
    rollover: r.read<bool>('rollover'),
  );

  /// Sets the monthly budget ([amount] micro-units of the main currency) of
  /// an expense category or group. Income is never budgeted.
  Future<Result<void, RepositoryDataError>> set(String id, int amount) =>
      transaction(() async {
        if (amount <= 0) return const Err(RepositoryDataError.invalidAmount);
        final categories = attachedDatabase.categoriesRepository;
        final category = await categories.findById(id);
        if (category != null) {
          if (await categories.kindOf(id) != CategoryKind.expense) {
            return const Err(RepositoryDataError.categoryKindMismatch);
          }
          await (update(categoriesTable)..where((c) => c.id.equals(id))).write(
            CategoriesTableCompanion(
              budgetAmount: Value(amount),
              budgetPeriod: const Value(BudgetPeriod.monthly),
            ),
          );
          return const Ok(null);
        }
        final group = await categories.findGroupById(id);
        if (group == null) return const Err(RepositoryDataError.notFound);
        if (group.kind != CategoryKind.expense) {
          return const Err(RepositoryDataError.categoryKindMismatch);
        }
        await (update(
          categoryGroupsTable,
        )..where((g) => g.id.equals(id))).write(
          CategoryGroupsTableCompanion(
            budgetAmount: Value(amount),
            budgetPeriod: const Value(BudgetPeriod.monthly),
          ),
        );
        return const Ok(null);
      });

  /// Clears the budget of a category or a group; both are left alone.
  Future<void> remove(String id) => transaction(() async {
    await (update(categoriesTable)..where((c) => c.id.equals(id))).write(
      const CategoriesTableCompanion(
        budgetAmount: Value(null),
        budgetPeriod: Value(null),
      ),
    );
    await (update(categoryGroupsTable)..where((g) => g.id.equals(id))).write(
      const CategoryGroupsTableCompanion(
        budgetAmount: Value(null),
        budgetPeriod: Value(null),
      ),
    );
  });

  /// Every budget with what non-hidden assets accounts spent on it in
  /// [month]; a group's budget counts every category inside it. Spending is
  /// positive; refunds reduce it.
  Stream<List<BudgetProgress>> watchProgress(YearMonth month) =>
      customSelect(
        '''
SELECT g.id AS id, 1 AS is_group, g.budget_amount AS amount,
  g.budget_period AS period, g.budget_rollover AS rollover,
  g.sort_order AS sort_order, t.currency AS spent_currency, -SUM(t.amount) AS spent
FROM category_groups g
LEFT JOIN categories c ON c.group_id = g.id
LEFT JOIN transactions t ON t.category_id = c.id AND t.deleted_at IS NULL
  AND t.type = 'expense' AND t.occurred_at >= ?1 AND t.occurred_at < ?2
  AND t.$visibleAccounts
WHERE g.budget_amount IS NOT NULL
GROUP BY g.id, t.currency
UNION ALL
SELECT c.id, 0, c.budget_amount, c.budget_period, c.budget_rollover,
  c.sort_order, t.currency, -SUM(t.amount)
FROM categories c
LEFT JOIN transactions t ON t.category_id = c.id AND t.deleted_at IS NULL
  AND t.type = 'expense' AND t.occurred_at >= ?1 AND t.occurred_at < ?2
  AND t.$visibleAccounts
WHERE c.budget_amount IS NOT NULL
GROUP BY c.id, t.currency
ORDER BY is_group DESC, sort_order''',
        variables: [
          wallClockVariable(month.start),
          wallClockVariable(month.end),
        ],
        readsFrom: {
          assetsAccountsTable,
          categoryGroupsTable,
          categoriesTable,
          transactionsTable,
        },
      ).watch().map((rows) {
        final progress = <String, BudgetProgress>{};
        for (final r in rows) {
          final budget = _budget(r);
          final spent = (progress[budget.targetId] ??= BudgetProgress(
            budget: budget,
            spent: {},
          )).spent;
          final currency = r.readNullable<String>('spent_currency');
          if (currency != null) spent[currency] = r.read<int>('spent');
        }
        return progress.values.toList();
      });
}
