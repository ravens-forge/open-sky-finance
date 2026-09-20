import 'package:drift/drift.dart';

import '../../core/dates/year_month.dart';
import '../database/app_database.dart';
import '../database/tables/assets_accounts_table.dart';
import '../database/tables/categories_table.dart';
import '../database/tables/transactions_table.dart';
import '../enums/category_kind.dart';
import '../enums/transaction_type.dart';
import '../models/income_expense.dart';
import 'report_sql.dart';

part 'income_expense_repository.g.dart';

@DriftAccessor(
  tables: [AssetsAccountsTable, CategoriesTable, TransactionsTable],
)
class IncomeExpenseRepository extends DatabaseAccessor<AppDatabase>
    with _$IncomeExpenseRepositoryMixin {
  IncomeExpenseRepository(super.attachedDatabase);

  /// Income and expenses of non-hidden assets accounts in [from, to).
  Stream<IncomeExpense> watchSummary(DateTime from, DateTime to) =>
      customSelect(
        '''
SELECT currency, type, SUM(amount) AS total FROM transactions
WHERE deleted_at IS NULL AND type IN ('income', 'expense')
  AND occurred_at >= ?1 AND occurred_at < ?2 AND $visibleAccounts
GROUP BY currency, type''',
        variables: [wallClockVariable(from), wallClockVariable(to)],
        readsFrom: {assetsAccountsTable, transactionsTable},
      ).watch().map((rows) => _addTo(IncomeExpense(), rows));

  /// Cash flow (and net income, [IncomeExpense.net]) per month of the chart
  /// accounts, for the months [from, to).
  Stream<Map<YearMonth, IncomeExpense>> watchCashFlow(
    YearMonth from,
    YearMonth to,
  ) =>
      customSelect(
        '''
WITH $chartAccountsCte
SELECT substr(occurred_at, 1, 7) AS month, currency, type,
  SUM(amount) AS total
FROM transactions
WHERE deleted_at IS NULL AND type IN ('income', 'expense')
  AND occurred_at >= ?1 AND occurred_at < ?2
  AND assets_account_id IN (SELECT id FROM chart_accounts)
GROUP BY 1, 2, 3''',
        variables: [wallClockVariable(from.start), wallClockVariable(to.start)],
        readsFrom: {assetsAccountsTable, transactionsTable},
      ).watch().map((rows) {
        final months = {
          for (var m = from; m.compareTo(to) < 0; m = m.plus(1))
            m: IncomeExpense(),
        };
        for (final r in rows) {
          final month = r.read<String>('month');
          _addTo(
            months[YearMonth(
              int.parse(month.substring(0, 4)),
              int.parse(month.substring(5)),
            )]!,
            [r],
          );
        }
        return months;
      });

  static IncomeExpense _addTo(IncomeExpense into, List<QueryRow> rows) {
    for (final r in rows) {
      final byCurrency = r.read<String>('type') == TransactionType.income.name
          ? into.income
          : into.expense;
      byCurrency[r.read<String>('currency')] = r.read<int>('total');
    }
    return into;
  }

  /// Expense (or income) totals per category group of non-hidden assets accounts
  /// in [from, to); a group includes every category inside it. The `null` key
  /// is uncategorized.
  Stream<Map<String?, Map<String, int>>> watchTotalsByGroup(
    CategoryKind kind,
    DateTime from,
    DateTime to,
  ) =>
      customSelect(
        '''
SELECT c.group_id AS group_id, t.currency AS currency,
  SUM(t.amount) AS total
FROM transactions t LEFT JOIN categories c ON c.id = t.category_id
WHERE t.deleted_at IS NULL AND t.type = ?1
  AND t.occurred_at >= ?2 AND t.occurred_at < ?3 AND t.$visibleAccounts
GROUP BY 1, 2''',
        variables: [
          Variable(kind.name),
          wallClockVariable(from),
          wallClockVariable(to),
        ],
        readsFrom: {assetsAccountsTable, categoriesTable, transactionsTable},
      ).watch().map((rows) {
        final groups = <String?, Map<String, int>>{};
        for (final r in rows) {
          final group = groups[r.readNullable<String>('group_id')] ??= {};
          group[r.read<String>('currency')] = r.read<int>('total');
        }
        return groups;
      });
}
