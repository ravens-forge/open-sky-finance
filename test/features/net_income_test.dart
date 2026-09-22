import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/providers.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;

  Future<void> open(WidgetTester tester, String path) async {
    container.read(routerProvider).go(path);
    await settle(tester);
  }

  testWidgets(
    'totals, savings rate, groups with their categories, drill-down',
    (tester) async {
      final now = DateTime(2026, 9, 17);
      container = await pumpApp(tester, now: now);
      db = container.read(appDatabaseProvider);
      late String checking;
      await tester.runAsync(() async {
        checking = await addAssetsAccount(db, 'Checking', currency: 'USD');
        final food = await addCategoryGroup(db, 'Food');
        final groceries = await addCategory(db, 'Groceries', groupId: food);
        final salaryGroup = await addCategoryGroup(
          db,
          'Salary',
          kind: CategoryKind.income,
        );
        final payroll = await addCategory(db, 'Payroll', groupId: salaryGroup);
        Future<void> tx(TransactionType type, int amount, String? categoryId) =>
            db.transactionsRepository.save(
              TransactionDraft(
                type: type,
                occurredAt: DateTime(2026, 9, 10),
                amount: amount,
                assetsAccountId: checking,
                categoryId: categoryId,
              ),
            );
        await tx(TransactionType.income, m(1000), payroll);
        await tx(TransactionType.expense, -m(300), groceries);
      });

      await open(tester, Routes.netIncome);

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Payroll'), findsOneWidget);
      expect(find.text('+\$700.00'), findsWidgets); // net income
      expect(find.text('Savings rate 70.0%'), findsOneWidget);

      await tester.ensureVisible(find.text('Groceries'));
      await settle(tester);
      await tester.tap(find.text('Groceries'));
      await settle(tester);
      expect(find.text('Filters (1)'), findsOneWidget);
    },
  );

  testWidgets('switching to Quarter disables category drill-down', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 17);
    container = await pumpApp(tester, now: now);
    db = container.read(appDatabaseProvider);
    await tester.runAsync(() async {
      final checking = await addAssetsAccount(db, 'Checking', currency: 'USD');
      final food = await addCategoryGroup(db, 'Food');
      final groceries = await addCategory(db, 'Groceries', groupId: food);
      await db.transactionsRepository.save(
        TransactionDraft(
          type: TransactionType.expense,
          occurredAt: DateTime(2026, 9, 10),
          amount: -m(300),
          assetsAccountId: checking,
          categoryId: groceries,
        ),
      );
    });

    await open(tester, Routes.netIncome);
    await tester.tap(find.text('Quarter'));
    await settle(tester);
    expect(find.text('Groceries'), findsOneWidget);

    await tester.tap(find.text('Groceries'));
    await settle(tester);
    expect(find.text('Filters (1)'), findsNothing);
  });
}
