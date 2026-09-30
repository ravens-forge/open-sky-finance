@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/widgets/info_tooltip.dart';
import 'package:open_sky_finance/data/database/app_database.dart';

import '../data/test_db.dart';
import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

/// The demo with a budget in every state, on groups and on categories:
/// over (Restaurants), near (Groceries and Utilities), used up (Housing) and
/// under (Transport, Subscriptions); Health and "Movies & events" have none.
Future<void> _seedBudgets(AppDatabase db) async {
  await seedDemo(db);
  ok(
    await db.budgetsRepository.setAll({
      for (final category in ['Rent', 'Fuel', 'Electricity'])
        demo[category]!: null,
      demo['Housing']!: m(850),
      demo['Groceries']!: m(160),
      demo['Restaurants']!: m(50),
      demo['Transport']!: m(500),
      demo['Utilities']!: m(100),
    }),
  );
}

/// Every transaction of the demo, and no budget.
Future<void> _seedNoBudgets(AppDatabase db) async {
  await seedDemo(db);
  final budgets = await db.budgetsRepository.watchAll().first;
  ok(
    await db.budgetsRepository.setAll({
      for (final budget in budgets) budget.targetId: null,
    }),
  );
}

Future<void> _budget(
  WidgetTester tester,
  ProviderContainer container,
  AppLocalizations l10n,
) async {
  container.read(routerProvider).go(Routes.budgets);
  await settle(tester);
}

void main() {
  appGolden('budget', height: 1140, seed: _seedBudgets, act: _budget);

  appGolden('budget_empty', seed: _seedNoBudgets, act: _budget);

  appGolden(
    'budget_tooltip',
    height: 1140,
    seed: _seedBudgets,
    act: (tester, container, l10n) async {
      await _budget(tester, container, l10n);
      await tester.tap(find.byType(InfoTooltip).at(1));
      await settle(tester);
    },
  );

  appGolden(
    'edit_budgets',
    height: 2000,
    seed: _seedBudgets,
    act: (tester, container, l10n) async {
      container.read(routerProvider).go(Routes.editBudgets);
      await settle(tester);
    },
  );
}
