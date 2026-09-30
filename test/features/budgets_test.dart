import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/features/budgets/widgets/edit_budget_row.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;
  late String food, groceries, restaurants, fuel;

  /// Food › Groceries (−90) and Restaurants (−60), Transport › Fuel (−40),
  /// all on September 10, 2026, in euros.
  Future<void> seed(AppDatabase db) async {
    await db.settingsRepository.set(SettingKeys.mainCurrency, 'EUR');
    final checking = await addAssetsAccount(db, 'Checking');
    food = await addCategoryGroup(db, 'Food');
    groceries = await addCategory(db, 'Groceries', groupId: food);
    restaurants = await addCategory(db, 'Restaurants', groupId: food);
    final transport = await addCategoryGroup(db, 'Transport');
    fuel = await addCategory(db, 'Fuel', groupId: transport);
    for (final (category, amount) in [
      (groceries, 90),
      (restaurants, 60),
      (fuel, 40),
    ]) {
      ok(
        await db.transactionsRepository.save(
          TransactionDraft(
            type: TransactionType.expense,
            occurredAt: DateTime(2026, 9, 10),
            amount: -m(amount),
            assetsAccountId: checking,
            categoryId: category,
          ),
        ),
      );
    }
  }

  Future<void> pump(
    WidgetTester tester, {
    Map<String, int> Function()? budgets,
  }) async {
    container = await pumpApp(
      tester,
      now: DateTime(2026, 9, 17),
      seed: (db) async {
        await seed(db);
        if (budgets != null) ok(await db.budgetsRepository.setAll(budgets()));
      },
    );
    db = container.read(appDatabaseProvider);
  }

  Future<void> open(WidgetTester tester, String path) async {
    container.read(routerProvider).go(path);
    await settle(tester);
  }

  testWidgets('rows by risk with their status, totals and not budgeted', (
    tester,
  ) async {
    await pump(tester, budgets: () => {groceries: m(100), restaurants: m(50)});
    await open(tester, Routes.budgets);

    // Over budget first.
    expect(
      tester.getTopLeft(find.text('Restaurants')).dy,
      lessThan(tester.getTopLeft(find.text('Groceries')).dy),
    );
    expect(find.text('120%'), findsOneWidget);
    expect(find.text('Over by €10.00'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('€10.00 left'), findsOneWidget);
    expect(find.text('€150.00'), findsNWidgets(2)); // budgeted and spent
    expect(find.text('€0.00'), findsOneWidget); // remaining
    expect(
      find.text(
        '100.0% spent · the marker shows day 17 of 30 (56.7% of the month)',
      ),
      findsOneWidget,
    );
    expect(find.text('Not budgeted: €40.00', findRichText: true), findsOne);

    // Another month has no marker to explain.
    await tester.tap(find.byTooltip('Previous month'));
    await settle(tester);
    expect(find.text('0.0% spent'), findsOneWidget);
    expect(find.textContaining('Not budgeted'), findsNothing);
  });

  testWidgets('a row opens its transactions: a group, every category in it', (
    tester,
  ) async {
    await pump(tester, budgets: () => {food: m(200)});
    await open(tester, Routes.budgets);
    expect(find.text('€50.00 left'), findsOneWidget);

    await tester.tap(find.text('Food'));
    await settle(tester);
    expect(find.text('Filters (1)'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Restaurants'), findsOneWidget);
    expect(find.text('Fuel'), findsNothing);
  });

  testWidgets('empty state, then Edit budgets saves every change at once', (
    tester,
  ) async {
    // Tall enough for every row of Edit budgets and its total.
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 1200);
    addTearDown(tester.view.reset);
    await pump(tester);
    await open(tester, Routes.budgets);
    expect(find.text('No budgets yet'), findsOneWidget);
    expect(
      find.text(
        'This month you spent €190.00 in expense categories without a budget.',
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Set budgets'));
    await settle(tester);
    expect(find.text('€150.00 spent in September'), findsOneWidget);
    expect(find.text('€90.00 spent'), findsOneWidget);

    Finder field(String name) => find.descendant(
      of: find.widgetWithText(EditBudgetRow, name),
      matching: find.byType(TextField),
    );
    // Not an amount: nothing is saved.
    await tester.enterText(field('Fuel'), '0');
    await tester.enterText(field('Food'), '1,200.50');
    await tester.pump();
    expect(find.text('Covered by the group budget'), findsNWidgets(2));
    await tester.tap(find.text('Save budgets'));
    await settle(tester);
    expect(
      find.text('Enter an amount above 0, or leave it empty'),
      findsOneWidget,
    );
    expect(
      await tester.runAsync(() => db.budgetsRepository.watchAll().first),
      isEmpty,
    );

    await tester.enterText(field('Fuel'), '30');
    await tester.pump();
    expect(find.text('€1,230.50'), findsOneWidget); // total budgeted
    await tester.tap(find.text('Save budgets'));
    await settle(tester);

    final saved = await tester.runAsync(
      () => db.budgetsRepository.watchAll().first,
    );
    expect(
      {for (final budget in saved!) budget.targetId: budget.amount},
      {food: m(1200.5), fuel: m(30)},
    );
    // Back on the Budget page, now with rows.
    expect(find.text('By category'), findsOneWidget);
    expect(find.text('Over by €10.00'), findsOneWidget);
  });
}
