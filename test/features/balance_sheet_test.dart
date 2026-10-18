import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/assets_account_type.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/features/balance_sheet/models/balance_sheet_compare_kind.dart';
import 'package:open_sky_finance/features/balance_sheet/models/balance_sheet_comparison.dart';
import 'package:open_sky_finance/features/balance_sheet/widgets/balance_change.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

/// The page's list, not the horizontal tab bar above it.
final _page = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

/// A change under a balance, not a balance or subtotal with the same text.
Finder _change(String text) =>
    find.descendant(of: find.byType(BalanceChange), matching: find.text(text));

void main() {
  late ProviderContainer container;
  late AppDatabase db;

  Future<void> open(WidgetTester tester, String path) async {
    container.read(routerProvider).go(path);
    await settle(tester);
  }

  testWidgets('net worth, grouped accounts, credit usage and hidden note', (
    tester,
  ) async {
    container = await pumpApp(tester);
    db = container.read(appDatabaseProvider);
    await tester.runAsync(() async {
      final checking = await addAssetsAccount(
        db,
        'Checking',
        currency: 'USD',
        openingBalance: m(1000),
      );
      await addAssetsAccount(
        db,
        'Visa',
        currency: 'USD',
        type: AssetsAccountType.creditCard,
        openingBalance: -m(300),
      );
      await addAssetsAccount(
        db,
        'Old savings',
        currency: 'USD',
        isHidden: true,
      );
      await addAssetsAccount(
        db,
        'Collectibles',
        currency: 'USD',
        openingBalance: m(500),
        excludeFromNetWorth: true,
      );
      // A transaction the next day must not count "as of" today.
      await db.transactionsRepository.save(
        TransactionDraft(
          type: TransactionType.expense,
          occurredAt: DateTime.now().add(const Duration(days: 2)),
          amount: -m(50),
          assetsAccountId: checking,
        ),
      );
    });

    await open(tester, Routes.balanceSheet);

    expect(find.text('Checking'), findsOneWidget);
    expect(find.text('Collectibles'), findsOneWidget);
    expect(find.text('Not in net worth'), findsOneWidget);
    // Scheduled expense two days out must not affect the "as of today" balance.
    expect(find.text('\$1,000.00'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Visa'), 200, scrollable: _page);
    expect(find.text('Visa'), findsOneWidget);
    // Hidden account left out entirely, with a note and a link.
    expect(find.text('Old savings'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('1 hidden assets account not included'),
      200,
      scrollable: _page,
    );

    await tester.tap(find.text('View assets accounts'));
    await settle(tester);
    expect(find.textContaining('Show hidden assets accounts'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('Old savings'), findsOneWidget);
  });

  testWidgets('a future "as of" date counts the scheduled transactions', (
    tester,
  ) async {
    container = await pumpApp(tester, now: DateTime(2026, 9, 17, 10));
    db = container.read(appDatabaseProvider);
    await tester.runAsync(() async {
      final checking = await addAssetsAccount(
        db,
        'Checking',
        currency: 'USD',
        openingBalance: m(1000),
      );
      await db.transactionsRepository.save(
        TransactionDraft(
          type: TransactionType.expense,
          occurredAt: DateTime(2026, 9, 20, 9),
          amount: -m(50),
          assetsAccountId: checking,
        ),
      );
    });
    await open(tester, Routes.balanceSheet);
    expect(find.text('\$1,000.00'), findsWidgets);

    await tester.tap(find.text('Sep 17, 2026'));
    await settle(tester);
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(find.text('Sep 20, 2026'), findsOneWidget);
    expect(find.text('\$950.00'), findsWidgets);
  });

  testWidgets('compares with the same day last month, or another date', (
    tester,
  ) async {
    container = await pumpApp(tester, now: DateTime(2026, 9, 17, 10));
    db = container.read(appDatabaseProvider);
    await tester.runAsync(() async {
      final checking = await addAssetsAccount(
        db,
        'Checking',
        currency: 'USD',
        openingBalance: m(1000),
      );
      final visa = await addAssetsAccount(
        db,
        'Visa',
        currency: 'USD',
        type: AssetsAccountType.creditCard,
      );
      for (final (account, amount, date) in [
        (checking, m(100), DateTime(2026, 8, 10, 9)),
        (checking, m(50), DateTime(2026, 9, 5, 9)),
        (visa, -m(30), DateTime(2026, 9, 1, 9)),
      ]) {
        await db.transactionsRepository.save(
          TransactionDraft(
            type: amount > 0 ? TransactionType.income : TransactionType.expense,
            occurredAt: date,
            amount: amount,
            assetsAccountId: account,
          ),
        );
      }
    });
    await open(tester, Routes.balanceSheet);

    expect(find.text('Same day last month'), findsOneWidget);
    expect(find.text('+\$20.00 (+1.8%)'), findsOneWidget);
    expect(find.text('since Aug 17, 2026'), findsOneWidget);
    expect(find.text('Aug 17 \$1,100.00'), findsOneWidget);
    expect(_change('+\$50.00'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Visa'), 200, scrollable: _page);
    expect(find.text('Aug 17 \$0.00'), findsOneWidget);
    expect(_change('−\$30.00'), findsOneWidget);

    await tester.tap(find.text('Same day last month'));
    await settle(tester);
    await tester.tap(find.text('End of last year · Dec 31, 2025'));
    await settle(tester);
    // From zero: the change has no percentage.
    expect(find.text('+\$1,120.00'), findsOneWidget);
    expect(find.text('since Dec 31, 2025'), findsOneWidget);

    await tester.tap(find.text('End of last year'));
    await settle(tester);
    await tester.tap(find.text("Don't compare"));
    await settle(tester);
    expect(find.textContaining('since'), findsNothing);
    expect(find.textContaining('Dec 31'), findsNothing);
  });

  test('comparison dates follow the "as of" date', () {
    DateTime? on(BalanceSheetCompareKind kind, DateTime asOf) =>
        BalanceSheetComparison(kind).dateFor(asOf);
    final march31 = DateTime(2026, 3, 31);
    expect(
      on(BalanceSheetCompareKind.sameDayLastMonth, march31),
      DateTime(2026, 2, 28),
    );
    expect(
      on(BalanceSheetCompareKind.sameDayLastMonth, DateTime(2026, 1, 15)),
      DateTime(2025, 12, 15),
    );
    expect(
      on(BalanceSheetCompareKind.endOfLastMonth, march31),
      DateTime(2026, 2, 28),
    );
    expect(
      on(BalanceSheetCompareKind.sameDayLastYear, DateTime(2028, 2, 29)),
      DateTime(2027, 2, 28),
    );
    expect(
      on(BalanceSheetCompareKind.endOfLastYear, march31),
      DateTime(2025, 12, 31),
    );
    expect(on(BalanceSheetCompareKind.none, march31), isNull);

    final picked = BalanceSheetComparison(
      BalanceSheetCompareKind.pickedDate,
      DateTime(2026, 5, 4),
    );
    expect(picked.encode(), 'date:2026-05-04');
    expect(BalanceSheetComparison.decode(picked.encode()), picked);
    expect(
      BalanceSheetComparison.decode('endOfLastYear').kind,
      BalanceSheetCompareKind.endOfLastYear,
    );
    expect(
      BalanceSheetComparison.decode('pickedDate'),
      BalanceSheetComparison.initial,
    );
    expect(BalanceSheetComparison.decode(null), BalanceSheetComparison.initial);
  });
}
