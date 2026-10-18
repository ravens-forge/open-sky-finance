@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/report_currency.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/assets_account_type.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';

import '../data/test_db.dart';
import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

/// The demo in euros plus assets accounts in seven other currencies, with
/// September spending in some of them. Nothing is ever converted.
Future<void> _seedCurrencies(AppDatabase db) async {
  await seedDemo(db);
  Future<String> account(
    String name,
    String currency,
    num opening, {
    AssetsAccountType type = AssetsAccountType.bank,
  }) => addAssetsAccount(
    db,
    name,
    currency: currency,
    type: type,
    openingBalance: m(opening),
  );
  final usd = await account('US checking', 'USD', 3120.40);
  await account('Buenos Aires savings', 'ARS', 1250000);
  await account('São Paulo checking', 'BRL', 3480);
  await account('Zürich savings', 'CHF', 18250);
  final gbp = await account(
    'London float',
    'GBP',
    480,
    type: AssetsAccountType.cash,
  );
  await account('Tokyo cash', 'JPY', 52000, type: AssetsAccountType.cash);

  Future<void> spend(String account, String title, num amount, int day) async {
    ok(
      await db.transactionsRepository.save(
        TransactionDraft(
          type: TransactionType.expense,
          occurredAt: DateTime(2026, 9, day, 12),
          amount: -m(amount),
          assetsAccountId: account,
          categoryId: demo['Restaurants'],
          title: title,
          labelIds: [demo['vacation']!],
        ),
      ),
    );
  }

  await spend(usd, 'Airport lunch', 18.50, 17);
  await spend(gbp, 'Pub dinner', 240, 10);
}

Future<void> _open(
  WidgetTester tester,
  ProviderContainer container,
  String path, {
  String? currency,
}) async {
  if (currency != null) {
    container.read(reportCurrencyChoiceProvider.notifier).pick(currency);
  }
  container.read(routerProvider).go(path);
  await settle(tester);
}

void main() {
  appGolden(
    'home_currencies',
    height: 1500,
    showHome: true,
    seed: _seedCurrencies,
    act: (tester, container, l10n) =>
        _open(tester, container, Routes.home, currency: 'USD'),
  );

  appGolden(
    'balance_sheet_currencies',
    seed: _seedCurrencies,
    act: (tester, container, l10n) =>
        _open(tester, container, Routes.balanceSheet, currency: 'USD'),
  );

  appGolden(
    'currency_picker_sheet',
    seed: _seedCurrencies,
    act: (tester, container, l10n) async {
      await _open(tester, container, Routes.balanceSheet, currency: 'USD');
      // The Currency row comes first.
      await tester.tap(find.byIcon(Icons.expand_more).first);
      await settle(tester);
    },
  );

  appGolden(
    'net_income_currencies',
    seed: _seedCurrencies,
    act: (tester, container, l10n) =>
        _open(tester, container, Routes.netIncome, currency: 'USD'),
  );

  appGolden(
    'assets_accounts_many_currencies',
    height: 1500,
    seed: _seedCurrencies,
    act: (tester, container, l10n) =>
        _open(tester, container, Routes.assetsAccounts),
  );

  appGolden(
    'transactions_currencies',
    seed: _seedCurrencies,
    act: (tester, container, l10n) =>
        _open(tester, container, Routes.transactions),
  );

  appGolden(
    'budget_currencies',
    height: 1000,
    seed: _seedCurrencies,
    act: (tester, container, l10n) => _open(tester, container, Routes.budgets),
  );

  appGolden(
    'labels_currencies',
    seed: _seedCurrencies,
    act: (tester, container, l10n) => _open(tester, container, Routes.labels),
  );

  appGolden(
    'default_currency_confirm',
    seed: _seedCurrencies,
    act: (tester, container, l10n) async {
      await _open(tester, container, Routes.settings);
      await tester.tap(find.text(l10n.settingsDefaultCurrency));
      await settle(tester);
      await tester.tap(find.text('AED'));
      await settle(tester);
    },
  );
}
