import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/l10n.dart';
import 'database/app_database.dart';
import 'database/seed.dart';
import 'repositories/assets_accounts_repository.dart';
import 'repositories/balances_repository.dart';
import 'repositories/budgets_repository.dart';
import 'repositories/categories_repository.dart';
import 'repositories/erase_repository.dart';
import 'repositories/exchange_rates_repository.dart';
import 'repositories/income_expense_repository.dart';
import 'repositories/labels_repository.dart';
import 'repositories/reminders_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/transactions_repository.dart';

part 'providers.g.dart';

/// The app database. Tests override it with `AppDatabase(executor:
/// NativeDatabase.memory())`.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(
    onCreated: (db) {
      // First launch: the user has not picked a language yet.
      final device = PlatformDispatcher.instance.locale;
      final locale = basicLocaleListResolution(
        PlatformDispatcher.instance.locales,
        AppLocalizations.supportedLocales,
      );
      return seedDefaults(
        db,
        lookupAppLocalizations(locale),
        currency: deviceCurrency(device),
      );
    },
  );
  ref.onDispose(db.close);
  return db;
}

/// The currency of the device's region (`es_MX` → `MXN`), `USD` when unknown.
String deviceCurrency(Locale locale) {
  try {
    return NumberFormat.simpleCurrency(
          locale: Intl.canonicalizedLocale(locale.toString()),
        ).currencyName ??
        'USD';
  } on ArgumentError {
    return 'USD';
  }
}

@Riverpod(keepAlive: true)
AssetsAccountsRepository assetsAccountsRepository(Ref ref) =>
    ref.watch(appDatabaseProvider).assetsAccountsRepository;

@Riverpod(keepAlive: true)
BalancesRepository balancesRepository(Ref ref) =>
    ref.watch(appDatabaseProvider).balancesRepository;

@Riverpod(keepAlive: true)
BudgetsRepository budgetsRepository(Ref ref) =>
    ref.watch(appDatabaseProvider).budgetsRepository;

@Riverpod(keepAlive: true)
CategoriesRepository categoriesRepository(Ref ref) =>
    ref.watch(appDatabaseProvider).categoriesRepository;

@Riverpod(keepAlive: true)
EraseRepository eraseRepository(Ref ref) =>
    ref.watch(appDatabaseProvider).eraseRepository;

@Riverpod(keepAlive: true)
ExchangeRatesRepository exchangeRatesRepository(Ref ref) =>
    ref.watch(appDatabaseProvider).exchangeRatesRepository;

@Riverpod(keepAlive: true)
IncomeExpenseRepository incomeExpenseRepository(Ref ref) =>
    ref.watch(appDatabaseProvider).incomeExpenseRepository;

@Riverpod(keepAlive: true)
LabelsRepository labelsRepository(Ref ref) =>
    ref.watch(appDatabaseProvider).labelsRepository;

@Riverpod(keepAlive: true)
RemindersRepository remindersRepository(Ref ref) =>
    ref.watch(appDatabaseProvider).remindersRepository;

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    ref.watch(appDatabaseProvider).settingsRepository;

@Riverpod(keepAlive: true)
TransactionsRepository transactionsRepository(Ref ref) =>
    ref.watch(appDatabaseProvider).transactionsRepository;
