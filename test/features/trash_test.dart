import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
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

  /// A wallet with "Bakery", "Cinema" and "Taxi" today, all but "Taxi" in
  /// the Trash.
  Future<void> start(WidgetTester tester) async {
    container = await pumpApp(tester);
    db = container.read(appDatabaseProvider);
    await tester.runAsync(() async {
      final wallet = await addAssetsAccount(db, 'Wallet', currency: 'USD');
      for (final title in ['Bakery', 'Cinema', 'Taxi']) {
        final id = ok(
          await db.transactionsRepository.save(
            TransactionDraft(
              type: TransactionType.expense,
              occurredAt: DateTime.now(),
              amount: -m(12.5),
              assetsAccountId: wallet,
              title: title,
            ),
          ),
        );
        if (title != 'Taxi') await db.transactionsRepository.trash(id);
      }
    });
  }

  testWidgets('trashed transactions are restored or deleted permanently', (
    tester,
  ) async {
    await start(tester);
    await open(tester, Routes.trash);

    expect(find.text('Deleted today'), findsOneWidget);
    expect(find.text('Bakery'), findsOneWidget);
    expect(find.text('Cinema'), findsOneWidget);
    expect(find.text('Taxi'), findsNothing);
    expect(find.textContaining('2 items'), findsOneWidget);

    await tester.tap(find.text('Restore').first);
    await settle(tester);
    expect(find.textContaining('1 item'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete permanently'));
    await settle(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete permanently'));
    await settle(tester);
    expect(find.text('The trash is empty'), findsOneWidget);

    final left = await tester.runAsync(
      () => db.transactionsRepository.live().get(),
    );
    expect(left!.length, 2);
  });

  testWidgets('"Empty" deletes everything after confirming', (tester) async {
    await start(tester);
    await open(tester, Routes.trash);

    await tester.tap(find.widgetWithText(TextButton, 'Empty'));
    await settle(tester);
    expect(find.text('Empty the trash?'), findsOneWidget);
    expect(
      find.textContaining('2 transactions are deleted permanently'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Empty'));
    await settle(tester);
    expect(find.text('The trash is empty'), findsOneWidget);

    final trash = await tester.runAsync(
      () => db.transactionsRepository.watchTrash().first,
    );
    expect(trash, isEmpty);
  });
}
