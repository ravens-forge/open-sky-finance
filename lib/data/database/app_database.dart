import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../enums/assets_account_type.dart';
import '../enums/budget_period.dart';
import '../enums/category_kind.dart';
import '../enums/reminder_frequency.dart';
import '../enums/transaction_type.dart';
import '../repositories/assets_accounts_repository.dart';
import '../repositories/balances_repository.dart';
import '../repositories/budgets_repository.dart';
import '../repositories/categories_repository.dart';
import '../repositories/exchange_rates_repository.dart';
import '../repositories/income_expense_repository.dart';
import '../repositories/labels_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/transactions_repository.dart';
import 'tables/assets_accounts_table.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/labels_table.dart';
import 'tables/reminder_labels_table.dart';
import 'tables/reminders_table.dart';
import 'tables/settings_table.dart';
import 'tables/transaction_labels_table.dart';
import 'tables/transactions_table.dart';
import 'tables/wall_clock_converter.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SettingsTable,
    AssetsAccountsTable,
    CategoriesTable,
    TransactionsTable,
    LabelsTable,
    TransactionLabelsTable,
    BudgetsTable,
    RemindersTable,
    ReminderLabelsTable,
  ],
  daos: [
    AssetsAccountsRepository,
    BalancesRepository,
    BudgetsRepository,
    CategoriesRepository,
    ExchangeRatesRepository,
    IncomeExpenseRepository,
    LabelsRepository,
    SettingsRepository,
    TransactionsRepository,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [onCreated] runs once, right after the tables are created (first launch).
  AppDatabase({QueryExecutor? executor, this.onCreated})
    : super(executor ?? driftDatabase(name: 'open_sky_finance'));

  final Future<void> Function(AppDatabase db)? onCreated;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.wasCreated) await onCreated?.call(this);
    },
  );
}
