import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/tables/assets_accounts_table.dart';
import '../database/tables/categories_table.dart';
import '../database/tables/category_groups_table.dart';
import '../database/tables/labels_table.dart';
import '../database/tables/reminders_table.dart';
import '../database/tables/transactions_table.dart';
import '../enums/transaction_type.dart';
import 'data_counts.dart';

/// Everything a backup holds, as the rows it is written back as: what an
/// export reads and a restore (or an import) replaces the data with.
@immutable
class AppSnapshot {
  const AppSnapshot({
    required this.appVersion,
    required this.exportedAt,
    required this.settings,
    required this.assetsAccounts,
    required this.categoryGroups,
    required this.categories,
    required this.labels,
    required this.reminders,
    required this.reminderLabels,
    required this.transactions,
    required this.transactionLabels,
  });

  /// Version of the app that wrote it.
  final String appVersion;

  /// UTC.
  final DateTime exportedAt;

  /// Stored values of the backed-up settings, by key: only
  /// `SettingKeys.backedUp`, and only those that are set.
  final Map<String, String> settings;
  final List<AssetsAccountTableRow> assetsAccounts;
  final List<CategoryGroupTableRow> categoryGroups;
  final List<CategoryTableRow> categories;
  final List<LabelTableRow> labels;
  final List<ReminderTableRow> reminders;
  final List<ReminderLabelTableRow> reminderLabels;

  /// The Trash included.
  final List<TransactionTableRow> transactions;
  final List<TransactionLabelTableRow> transactionLabels;

  /// Counted the way "Erase all data" counts the database.
  DataCounts get counts => DataCounts(
    assetsAccounts: assetsAccounts.length,
    transactions: transactions
        .where(
          (t) =>
              t.deletedAt == null && t.type != TransactionType.openingBalance,
        )
        .length,
    reminders: reminders.length,
    budgets:
        categoryGroups.where((g) => g.budgetAmount != null).length +
        categories.where((c) => c.budgetAmount != null).length,
    labels: labels.length,
    categories: categories.length,
    trashed: transactions.where((t) => t.deletedAt != null).length,
  );
}
