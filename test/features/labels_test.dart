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

  /// A wallet with "Bakery" labelled [label] and an unlabelled "Cinema",
  /// both today.
  Future<void> start(WidgetTester tester, String label) async {
    container = await pumpApp(tester);
    db = container.read(appDatabaseProvider);
    await tester.runAsync(() async {
      final wallet = await addAssetsAccount(db, 'Wallet', currency: 'USD');
      final labelId = ok(await db.labelsRepository.save(name: label));
      for (final (title, labels) in [
        ('Bakery', [labelId]),
        ('Cinema', <String>[]),
      ]) {
        ok(
          await db.transactionsRepository.save(
            TransactionDraft(
              type: TransactionType.expense,
              occurredAt: DateTime.now(),
              amount: -m(12.5),
              assetsAccountId: wallet,
              title: title,
              labelIds: labels,
            ),
          ),
        );
      }
      ok(await db.labelsRepository.save(name: 'home'));
    });
  }

  testWidgets('each label shows its month; tapping one opens its '
      'transactions', (tester) async {
    await start(tester, 'vacation');
    await open(tester, Routes.labels);

    expect(find.text('vacation'), findsOneWidget);
    expect(find.text('1 transaction'), findsOneWidget);
    expect(find.text('−\$12.50'), findsOneWidget);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('No transactions this month'), findsOneWidget);

    await tester.tap(find.text('vacation'));
    await settle(tester);
    expect(find.text('Bakery'), findsOneWidget);
    expect(find.text('Cinema'), findsNothing);
    expect(find.text('Filters (1)'), findsOneWidget);
  });

  testWidgets('labels are created, renamed and deleted', (tester) async {
    await start(tester, 'vacation');
    await open(tester, Routes.labels);

    await tester.tap(find.text('New label'));
    await settle(tester);
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.enterText(find.byType(TextField), 'VACATION');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('This name is already used'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'car');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('car'), findsOneWidget);

    await tester.longPress(find.text('car'));
    await settle(tester);
    await tester.tap(find.text('Rename'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'bike');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('car'), findsNothing);
    expect(find.text('bike'), findsOneWidget);

    await tester.longPress(find.text('vacation'));
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(
      find.textContaining('It is removed from 1 transaction'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
    await settle(tester);
    expect(find.text('vacation'), findsNothing);

    await open(tester, Routes.transactions);
    expect(find.text('Bakery'), findsOneWidget);
  });
}
