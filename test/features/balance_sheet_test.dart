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

import '../data/test_db.dart';
import '../pump_app.dart';

/// The page's list, not the horizontal tab bar above it.
final _page = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

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
}
