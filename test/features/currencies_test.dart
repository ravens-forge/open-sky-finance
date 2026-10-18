import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/report_currency.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/data/providers.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

/// Totals never mix currencies: lists show one line per currency, reports
/// one currency at a time, budgets only the default currency.
void main() {
  Future<void> open(
    WidgetTester tester,
    ProviderContainer container,
    String path,
  ) async {
    container.read(routerProvider).go(path);
    await settle(tester);
  }

  Future<void> euros(AppDatabase db) =>
      db.settingsRepository.set(SettingKeys.defaultCurrency, 'EUR');

  testWidgets('the Balance sheet shows one currency; the row switches it', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      seed: (db) async {
        await euros(db);
        await addAssetsAccount(db, 'Checking', openingBalance: m(100));
        await addAssetsAccount(
          db,
          'US checking',
          currency: 'USD',
          openingBalance: m(30),
        );
        await addAssetsAccount(db, 'Old', currency: 'GBP', isHidden: true);
      },
    );
    await open(tester, container, Routes.balanceSheet);

    // The hidden GBP account adds no choice; EUR comes first.
    expect(find.text('CURRENCY'), findsOneWidget);
    expect(find.text('EUR · Euro'), findsOneWidget);
    expect(find.text('Checking'), findsOneWidget);
    expect(find.text('US checking'), findsNothing);

    await tester.tap(find.text('EUR · Euro'));
    await settle(tester);
    expect(find.text('Default · 1 assets account'), findsOneWidget);
    expect(find.text('GBP'), findsNothing);
    await tester.tap(find.text('USD · US dollar'));
    await settle(tester);

    expect(find.text('US checking'), findsOneWidget);
    expect(find.text('Checking'), findsNothing);
    // Nothing converted: the net worth is the USD balance alone.
    expect(find.text(r'$30.00'), findsWidgets);
    expect(find.textContaining('130'), findsNothing);
  });

  testWidgets('one currency: no Currency row', (tester) async {
    final container = await pumpApp(
      tester,
      seed: (db) async {
        await euros(db);
        await addAssetsAccount(db, 'Checking', openingBalance: m(100));
      },
    );
    await open(tester, container, Routes.balanceSheet);
    expect(find.text('CURRENCY'), findsNothing);
  });

  testWidgets('subtotals fold after three currencies', (tester) async {
    final container = await pumpApp(
      tester,
      seed: (db) async {
        await euros(db);
        for (final (i, code) in ['EUR', 'USD', 'GBP', 'CHF', 'JPY'].indexed) {
          await addAssetsAccount(
            db,
            'Account $code',
            currency: code,
            openingBalance: m(i + 1),
          );
        }
      },
    );
    await open(tester, container, Routes.assetsAccounts);

    // EUR, then CHF and GBP by code; JPY and USD folded.
    final header = find.ancestor(
      of: find.text('Assets'),
      matching: find.byType(Row),
    );
    Finder inHeader(String digits) => find.descendant(
      of: header.first,
      matching: find.textContaining(digits),
    );
    expect(inHeader('1.00'), findsOneWidget);
    expect(inHeader('4.00'), findsOneWidget);
    expect(inHeader('3.00'), findsOneWidget);
    expect(inHeader('2.00'), findsNothing);

    await tester.tap(find.text('+2 more currencies'));
    await settle(tester);
    expect(inHeader('2.00'), findsOneWidget);
    expect(inHeader('5'), findsOneWidget);
    expect(find.text('Show fewer'), findsOneWidget);
  });

  testWidgets('Home budgets stay in the default currency', (tester) async {
    final container = await pumpApp(
      tester,
      showHome: true,
      seed: (db) async {
        await euros(db);
        await addAssetsAccount(db, 'Checking', openingBalance: m(100));
        await addAssetsAccount(db, 'US checking', currency: 'USD');
        final group = await addCategoryGroup(db, 'Food');
        final groceries = await addCategory(db, 'Groceries', groupId: group);
        await db.budgetsRepository.set(groceries, m(200));
      },
    );
    container.read(reportCurrencyChoiceProvider.notifier).pick('USD');
    await settle(tester);

    final note = find.text(
      "Budgets are in EUR, your default currency. They don't count spending "
      'in USD.',
    );
    await tester.ensureVisible(note);
    await tester.tap(find.text('Show EUR'));
    await settle(tester);
    expect(note, findsNothing);
    expect(await container.read(reportCurrencyProvider.future), 'EUR');
  });

  testWidgets('a new default currency asks first when budgets exist', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      seed: (db) async {
        await euros(db);
        final group = await addCategoryGroup(db, 'Food');
        await db.budgetsRepository.set(group, m(200));
      },
    );
    final db = container.read(appDatabaseProvider);
    await open(tester, container, Routes.settings);

    Future<void> pickAed() async {
      await tester.tap(find.text('Default currency'));
      await settle(tester);
      await tester.tap(find.text('AED'));
      await settle(tester);
    }

    await pickAed();
    expect(find.text('Use AED as default currency?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(
      await tester.runAsync(
        () => db.settingsRepository.get(SettingKeys.defaultCurrency),
      ),
      'EUR',
    );

    await pickAed();
    await tester.tap(find.text('Use AED'));
    await settle(tester);
    expect(
      await tester.runAsync(
        () => db.settingsRepository.get(SettingKeys.defaultCurrency),
      ),
      'AED',
    );
  });
}
