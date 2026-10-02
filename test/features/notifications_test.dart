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
import 'package:open_sky_finance/services/notifications/notifications_service.dart';

import '../data/test_db.dart';
import '../pump_app.dart';
import 'fake_notifications.dart';

/// Several database round trips: a stream update, then reads and writes.
Future<void> _settleLong(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await settle(tester);
  }
}

void main() {
  late ProviderContainer container;
  late AppDatabase db;
  late FakeNotifications notifications;

  Future<void> start(
    WidgetTester tester, {
    bool granted = true,
    Future<void> Function(AppDatabase db)? seed,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    notifications = FakeNotifications(granted: granted);
    container = await pumpApp(
      tester,
      now: DateTime(2026, 9, 17, 10, 30),
      overrides: [
        notificationsServiceProvider.overrideWithValue(notifications),
      ],
      seed: seed,
    );
    db = container.read(appDatabaseProvider);
  }

  testWidgets('reminders with Notify me are scheduled at their due date', (
    tester,
  ) async {
    await start(
      tester,
      seed: (db) async {
        final wallet = await addAssetsAccount(db, 'Wallet');
        await addReminder(
          db,
          'rent',
          assetsAccountId: wallet,
          title: 'Rent',
          nextDueAt: '2026-09-25T09:00:00',
        );
        await addReminder(
          db,
          'gym',
          assetsAccountId: wallet,
          title: 'Gym',
          nextDueAt: '2026-09-20T09:00:00',
        );
        // Overdue: the Reminders page shows it, no notification.
        await addReminder(
          db,
          'old',
          assetsAccountId: wallet,
          title: 'Old',
          nextDueAt: '2026-09-10T09:00:00',
        );
        await db.customStatement('UPDATE reminders SET notify = 1');
        await db.customStatement(
          "UPDATE reminders SET is_paused = 1 WHERE id = 'gym'",
        );
      },
    );
    expect(notifications.opened, isTrue);
    expect(notifications.scheduled.map((n) => (n.title, n.at, n.route)), [
      ('Rent', DateTime(2026, 9, 25, 9), Routes.reminder('rent')),
    ]);
    expect(notifications.scheduled.single.body, isNot(contains('1.00')));

    await tester.runAsync(
      () => db.customUpdate(
        'UPDATE reminders SET notify = 0',
        updates: {db.remindersTable},
      ),
    );
    await _settleLong(tester);
    expect(notifications.scheduled, isEmpty);
  });

  testWidgets('budget alerts ask for the permission', (tester) async {
    await start(tester, granted: false);
    container.read(routerProvider).go(Routes.settings);
    await settle(tester);

    await tester.tap(find.text('Budget alerts'));
    await settle(tester);
    expect(
      find.text(
        'Notifications are off for Open Sky Finance. '
        'Turn them on in the system settings.',
      ),
      findsOneWidget,
    );
    expect(await db.settingsRepository.get(SettingKeys.budgetAlerts), isNull);

    notifications.granted = true;
    await tester.tap(find.text('Budget alerts'));
    await settle(tester);
    expect(await db.settingsRepository.get(SettingKeys.budgetAlerts), 'true');
  });

  testWidgets('a used-up budget alerts once a month', (tester) async {
    Future<void> seed(AppDatabase db) async {
      await db.settingsRepository.set(SettingKeys.budgetAlerts, 'true');
      await db.settingsRepository.set(SettingKeys.mainCurrency, 'EUR');
      final wallet = await addAssetsAccount(db, 'Wallet');
      final food = await addCategoryGroup(db, 'Food');
      final groceries = await addCategory(db, 'Groceries', groupId: food);
      final rent = await addCategory(db, 'Rent', groupId: food);
      ok(await db.budgetsRepository.set(groceries, m(100)));
      ok(await db.budgetsRepository.set(rent, m(900)));
      for (final (category, units) in [(groceries, 100), (rent, 50)]) {
        ok(
          await db.transactionsRepository.save(
            TransactionDraft(
              type: TransactionType.expense,
              occurredAt: DateTime(2026, 9, 16),
              amount: -m(units),
              assetsAccountId: wallet,
              categoryId: category,
            ),
          ),
        );
      }
    }

    await start(tester, seed: seed);
    await _settleLong(tester);
    expect(notifications.shown.map((n) => (n.title, n.route)), [
      ('Budget used up: Groceries', Routes.budgets),
    ]);
    expect(
      await db.settingsRepository.get(SettingKeys.budgetAlertsSent),
      contains('2026-9'),
    );
  });
}
