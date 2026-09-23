import 'package:drift/drift.dart';

import '../../core/l10n.dart';
import '../database/app_database.dart';
import '../database/seed.dart';
import '../models/data_counts.dart';
import 'setting_keys.dart';

part 'erase_repository.g.dart';

@DriftAccessor()
class EraseRepository extends DatabaseAccessor<AppDatabase>
    with _$EraseRepositoryMixin {
  EraseRepository(super.attachedDatabase);

  Future<DataCounts> counts() async {
    final row = await customSelect('''
SELECT
  (SELECT COUNT(*) FROM assets_accounts) AS assets_accounts,
  (SELECT COUNT(*) FROM transactions
    WHERE deleted_at IS NULL AND type <> 'openingBalance') AS transactions,
  (SELECT COUNT(*) FROM reminders) AS reminders,
  (SELECT COUNT(*) FROM category_groups WHERE budget_amount IS NOT NULL)
    + (SELECT COUNT(*) FROM categories WHERE budget_amount IS NOT NULL)
    AS budgets,
  (SELECT COUNT(*) FROM labels) AS labels,
  (SELECT COUNT(*) FROM categories) AS categories,
  (SELECT COUNT(*) FROM transactions WHERE deleted_at IS NOT NULL) AS trashed
''').getSingle();
    return DataCounts(
      assetsAccounts: row.read('assets_accounts'),
      transactions: row.read('transactions'),
      reminders: row.read('reminders'),
      budgets: row.read('budgets'),
      labels: row.read('labels'),
      categories: row.read('categories'),
      trashed: row.read('trashed'),
    );
  }

  /// Deletes every financial row (the Trash too) and every setting but
  /// [SettingKeys.keptOnErase], which also turns automatic backups off, then
  /// seeds the defaults again in [l10n]'s language and [currency]. All or
  /// nothing: on failure the data stays as it was.
  Future<void> eraseAll(AppLocalizations l10n, {required String currency}) =>
      transaction(() async {
        final db = attachedDatabase;
        await deleteFinancialRows();
        await (delete(
          db.settingsTable,
        )..where((s) => s.key.isNotIn(SettingKeys.keptOnErase))).go();
        await seedDefaults(db, l10n, currency: currency);
      });

  /// Deletes every row but the settings. Callers run it inside their own
  /// transaction.
  Future<void> deleteFinancialRows() async {
    final db = attachedDatabase;
    // Children first, for the foreign keys. Typed deletes, so open streams
    // update.
    for (final table in <TableInfo<Table, Object?>>[
      db.transactionLabelsTable,
      db.reminderLabelsTable,
      db.transactionsTable,
      db.remindersTable,
      db.labelsTable,
      db.categoriesTable,
      db.categoryGroupsTable,
      db.assetsAccountsTable,
    ]) {
      await delete(table).go();
    }
  }

  /// Rewrites the file so deleted rows do not linger in it. Not allowed
  /// inside a transaction.
  Future<void> vacuum() => customStatement('VACUUM');
}
