import 'package:drift/drift.dart';

import '../../core/dates/year_month.dart';
import '../../core/ids.dart';
import '../../core/result.dart';
import '../database/app_database.dart';
import '../database/tables/assets_accounts_table.dart';
import '../database/tables/budgets_table.dart';
import '../database/tables/categories_table.dart';
import '../database/tables/transactions_table.dart';
import '../enums/budget_period.dart';
import '../enums/category_kind.dart';
import '../models/budget.dart';
import 'repository_data_error.dart';
import 'report_sql.dart';
import '../models/budget_progress.dart';

part 'budgets_repository.g.dart';

@DriftAccessor(
  tables: [
    BudgetsTable,
    AssetsAccountsTable,
    CategoriesTable,
    TransactionsTable,
  ],
)
class BudgetsRepository extends DatabaseAccessor<AppDatabase>
    with _$BudgetsRepositoryMixin {
  BudgetsRepository(super.attachedDatabase);

  Stream<List<Budget>> watchAll() =>
      select(budgetsTable).map((r) => r.toDomain()).watch();

  /// Sets the monthly budget ([amount] micro-units of the main currency) of an
  /// expense category or group, replacing its previous one.
  Future<Result<void, RepositoryDataError>> set(
    String categoryId,
    int amount,
  ) => transaction(() async {
    if (amount <= 0) return const Err(RepositoryDataError.invalidAmount);
    final category = await attachedDatabase.categoriesRepository.findById(
      categoryId,
    );
    if (category == null) return const Err(RepositoryDataError.notFound);
    if (category.kind != CategoryKind.expense) {
      return const Err(RepositoryDataError.categoryKindMismatch);
    }
    await into(budgetsTable).insert(
      BudgetsTableCompanion.insert(
        id: newId(),
        categoryId: categoryId,
        amount: amount,
        period: BudgetPeriod.monthly,
      ),
      onConflict: DoUpdate(
        (_) => BudgetsTableCompanion(amount: Value(amount)),
        target: [budgetsTable.categoryId],
      ),
    );
    return const Ok(null);
  });

  Future<void> remove(String categoryId) => (delete(
    budgetsTable,
  )..where((b) => b.categoryId.equals(categoryId))).go();

  /// Every budget with what non-hidden assets accounts spent on its category
  /// (and, for a group, its subcategories) in [month]. Spending is positive;
  /// refunds reduce it.
  Stream<List<BudgetProgress>> watchProgress(YearMonth month) =>
      customSelect(
        '''
SELECT b.*, t.currency AS spent_currency, -SUM(t.amount) AS spent
FROM budgets b
LEFT JOIN categories c ON c.id = b.category_id OR c.parent_id = b.category_id
LEFT JOIN transactions t ON t.category_id = c.id AND t.deleted_at IS NULL
  AND t.type = 'expense' AND t.occurred_at >= ?1 AND t.occurred_at < ?2
  AND t.$visibleAccounts
GROUP BY b.id, t.currency''',
        variables: [
          wallClockVariable(month.start),
          wallClockVariable(month.end),
        ],
        readsFrom: {
          assetsAccountsTable,
          categoriesTable,
          transactionsTable,
          budgetsTable,
        },
      ).watch().map((rows) {
        final progress = <String, BudgetProgress>{};
        for (final r in rows) {
          final budget = budgetsTable.map(r.data).toDomain();
          final spent = (progress[budget.id] ??= BudgetProgress(
            budget: budget,
            spent: {},
          )).spent;
          final currency = r.readNullable<String>('spent_currency');
          if (currency != null) spent[currency] = r.read<int>('spent');
        }
        return progress.values.toList();
      });
}
