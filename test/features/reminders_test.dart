import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/reminder_frequency.dart';
import 'package:open_sky_finance/data/enums/reminder_status.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/money.dart';
import 'package:open_sky_finance/data/models/reminder.dart';
import 'package:open_sky_finance/data/models/reminder_draft.dart';
import 'package:open_sky_finance/data/models/reminder_schedule.dart';
import 'package:open_sky_finance/data/models/timestamps.dart';
import 'package:open_sky_finance/data/models/transaction.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/features/reminders/models/reminder_sections.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

/// "Now" in these tests: Thursday, September 17, 2026.
final _now = DateTime(2026, 9, 17, 10, 30);

Reminder _reminder(String id, DateTime due, {bool autoPost = false}) =>
    Reminder(
      id: id,
      type: TransactionType.expense,
      title: id,
      amount: const Money(-1000000, 'EUR'),
      assetsAccountId: 'account',
      transfer: null,
      categoryId: null,
      notes: '',
      schedule: ReminderSchedule(
        frequency: ReminderFrequency.monthly,
        startDate: due,
        nextDueAt: due,
      ),
      autoPost: autoPost,
      notify: false,
      isPaused: false,
      sortOrder: 0,
      timestamps: Timestamps.at(DateTime(2026)),
    );

void main() {
  test('sections: overdue up to today, 30 days ahead, then later', () {
    final today = DateTime(2026, 9, 17);
    final sections = ReminderSections.of([
      _reminder('late', DateTime(2026, 9, 15)),
      _reminder('today', DateTime(2026, 9, 17, 23)),
      // Records itself on the next start: never waits for Record or Skip.
      _reminder('auto', DateTime(2026, 9, 16), autoPost: true),
      _reminder('tomorrow', DateTime(2026, 9, 18)),
      _reminder('day 30', DateTime(2026, 10, 17)),
      _reminder('day 31', DateTime(2026, 10, 18)),
    ], today);
    expect(sections.overdue.map((r) => r.id), ['late', 'today']);
    expect(sections.next.map((r) => r.id), ['auto', 'tomorrow', 'day 30']);
    expect(sections.later.map((r) => r.id), ['day 31']);
  });

  group('screens', () {
    late ProviderContainer container;
    late AppDatabase db;
    late String wallet;

    /// A monthly reminder of 40 due on [due].
    Future<String> addDue(
      AppDatabase db,
      String title,
      DateTime due, {
      bool autoPost = false,
    }) async => ok(
      await db.remindersRepository.save(
        ReminderDraft(
          template: TransactionDraft(
            type: TransactionType.expense,
            occurredAt: due,
            amount: -m(40),
            assetsAccountId: wallet,
            title: title,
          ),
          schedule: ReminderSchedule(
            frequency: ReminderFrequency.monthly,
            startDate: due,
            nextDueAt: due,
          ),
          autoPost: autoPost,
        ),
      ),
    );

    Future<void> start(
      WidgetTester tester, {
      Future<void> Function(AppDatabase db)? seed,
    }) async {
      // Tall enough for a whole form: lists build their rows lazily.
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(500, 2000);
      addTearDown(tester.view.reset);
      container = await pumpApp(
        tester,
        now: _now,
        seed: (db) async {
          wallet = await addAssetsAccount(db, 'Wallet');
          await seed?.call(db);
        },
      );
      db = container.read(appDatabaseProvider);
    }

    Future<void> open(WidgetTester tester, String path) async {
      container.read(routerProvider).go(path);
      await settle(tester);
    }

    Future<List<Reminder>> reminders(WidgetTester tester) async =>
        (await tester.runAsync(() => db.remindersRepository.watchAll().first))!;

    Future<List<Transaction>> recorded(WidgetTester tester, String id) async =>
        (await tester.runAsync(
          () => db.transactionsRepository.watchByReminder(id).first,
        ))!;

    testWidgets('no reminders: the empty state opens the editor', (
      tester,
    ) async {
      await start(tester);
      await open(tester, Routes.reminders);
      expect(find.text('No reminders yet'), findsOneWidget);

      await tester.tap(find.text('New reminder'));
      await settle(tester);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Frequency'), findsOneWidget);
    });

    testWidgets('Record adds the transaction and Undo takes it back, Skip '
        'only moves on', (tester) async {
      late String id;
      await start(
        tester,
        seed: (db) async =>
            id = await addDue(db, 'Internet', DateTime(2026, 9, 15)),
      );
      await open(tester, Routes.reminders);
      expect(find.text('Active · 1'), findsOneWidget);
      expect(
        find.textContaining('1 overdue reminder.', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Was due Sep 15'), findsOneWidget);

      await tester.tap(find.text('Record'));
      await settle(tester);
      expect(find.text('Recorded'), findsOneWidget);
      expect(find.text('Oct 15 · in 28 days'), findsOneWidget);
      expect(
        (await recorded(tester, id)).single.occurredAt,
        DateTime(2026, 9, 15),
      );

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Was due Sep 15'), findsOneWidget);
      expect(await recorded(tester, id), isEmpty);

      await tester.tap(find.text('Skip'));
      await settle(tester);
      expect(find.text('Oct 15 · in 28 days'), findsOneWidget);
      expect(await recorded(tester, id), isEmpty);
    });

    testWidgets('the form saves a new reminder', (tester) async {
      await start(tester);
      await open(tester, Routes.newReminder);

      await tester.enterText(find.byType(TextField).first, '14.99');
      await tester.enterText(find.byType(TextField).at(1), 'Music');
      await settle(tester);
      await tester.ensureVisible(find.text('Weekly'));
      await tester.tap(find.text('Weekly'));
      await settle(tester);
      expect(find.text('1 week'), findsOneWidget);
      expect(
        find.text('Next dates: Sep 17 · Sep 24 · Oct 1, 2026'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);

      final saved = (await reminders(tester)).single;
      expect(saved.title, 'Music');
      // An expense by default, typed positive.
      expect(saved.amount.micros, -m(14.99));
      expect(saved.schedule.frequency, ReminderFrequency.weekly);
      expect(saved.schedule.nextDueAt, DateTime(2026, 9, 17));
      expect(saved.autoPost, isFalse);
    });

    testWidgets('its page pauses it with Save changes and deletes it after '
        'confirming', (tester) async {
      late String id;
      await start(
        tester,
        seed: (db) async =>
            id = await addDue(db, 'Internet', DateTime(2026, 9, 25)),
      );
      await open(tester, Routes.reminder(id));
      expect(find.text('Next due Sep 25 · in 8 days'), findsOneWidget);
      expect(find.text('Monthly · never ends'), findsOneWidget);
      expect(find.text('Nothing recorded yet.'), findsOneWidget);

      await tester.tap(find.text('Pause reminder'));
      await tester.tap(find.text('Save changes'));
      await settle(tester);
      expect((await reminders(tester)).single.status, ReminderStatus.paused);

      await open(tester, Routes.reminder(id));
      await tester.tap(find.text('Delete'));
      await settle(tester);
      expect(find.text('Delete this reminder?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await settle(tester);
      expect(await reminders(tester), isEmpty);
    });

    testWidgets('a reminder that does not exist shows the not-found page', (
      tester,
    ) async {
      await start(tester);
      await open(tester, Routes.reminder('gone'));
      expect(find.text('Go to Home'), findsOneWidget);
    });

    testWidgets('automatic reminders are recorded when the app starts', (
      tester,
    ) async {
      late String id;
      await start(
        tester,
        seed: (db) async => id = await addDue(
          db,
          'Savings plan',
          DateTime(2026, 8, 10),
          autoPost: true,
        ),
      );
      expect(find.text('2 reminders recorded'), findsOneWidget);
      expect((await recorded(tester, id)).map((t) => t.occurredAt), [
        DateTime(2026, 9, 10),
        DateTime(2026, 8, 10),
      ]);
    });

    testWidgets('Repeat saves the transaction and its reminder', (
      tester,
    ) async {
      await start(tester);
      await open(tester, Routes.newTransaction(TransactionType.expense));

      await tester.enterText(find.byType(TextField).first, '9');
      await tester.enterText(find.byType(TextField).at(1), 'Streaming');
      await settle(tester);
      await tester.ensureVisible(find.text('Does not repeat'));
      await tester.tap(find.text('Does not repeat'));
      await settle(tester);
      await tester.tap(find.text('Monthly'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);

      expect(find.text('Reminder created'), findsOneWidget);
      final reminder = (await reminders(tester)).single;
      expect(reminder.title, 'Streaming');
      // Dated today: recorded now, due again in a month.
      expect(reminder.schedule.nextDueAt, DateTime(2026, 10, 17, 10, 30));
      expect(await recorded(tester, reminder.id), hasLength(1));
    });
  });
}
