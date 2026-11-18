import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/reminder_frequency.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/money.dart';
import 'package:open_sky_finance/data/models/reminder_schedule.dart';
import 'package:open_sky_finance/data/models/timestamps.dart';
import 'package:open_sky_finance/data/models/transaction.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/models/transaction_filter.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/features/transactions/models/transaction_form_values.dart';
import 'package:open_sky_finance/features/transactions/models/transactions_month.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

Transaction _transaction(
  String id,
  DateTime occurredAt,
  int micros, {
  TransactionType type = TransactionType.expense,
  String currency = 'EUR',
}) => Transaction(
  id: id,
  type: type,
  occurredAt: occurredAt,
  title: id,
  amount: Money(micros, currency),
  assetsAccountId: 'account',
  transfer: null,
  categoryId: null,
  notes: '',
  reminderId: null,
  deletedAt: null,
  timestamps: Timestamps(createdAt: DateTime(2026), updatedAt: DateTime(2026)),
);

/// An expense of [amount] units today, so it lands in the current month.
Future<String> _addToday(
  WidgetTester tester,
  AppDatabase db, {
  required String assetsAccountId,
  required String title,
  int amount = -10,
}) async => (await tester.runAsync(
  () async => ok(
    await db.transactionsRepository.save(
      TransactionDraft(
        type: TransactionType.expense,
        occurredAt: DateTime.now(),
        amount: m(amount),
        assetsAccountId: assetsAccountId,
        title: title,
      ),
    ),
  ),
))!;

void main() {
  test(
    'the month splits scheduled rows, groups days and sums per currency',
    () {
      final tomorrow = DateTime(2026, 9, 18);
      final month = TransactionsMonth.of([
        _transaction('rent', DateTime(2026, 9, 25, 9), -m(850)),
        _transaction('bakery', DateTime(2026, 9, 17, 18), -m(5)),
        _transaction('market', DateTime(2026, 9, 17, 10), -m(40)),
        _transaction(
          'salary',
          DateTime(2026, 9, 15, 8),
          m(3200),
          type: TransactionType.income,
        ),
        _transaction(
          'savings',
          DateTime(2026, 9, 15, 8),
          m(450),
          type: TransactionType.transfer,
        ),
        _transaction(
          'dollars',
          DateTime(2026, 9, 14, 8),
          -m(20),
          currency: 'USD',
        ),
      ], tomorrow);

      expect([for (final t in month.scheduled) t.id], ['rent']);
      expect(month.scheduledNet, {'EUR': -m(850)});
      expect(
        [for (final d in month.days) d.date],
        [DateTime(2026, 9, 17), DateTime(2026, 9, 15), DateTime(2026, 9, 14)],
      );
      expect(
        [for (final t in month.days.first.transactions) t.id],
        ['bakery', 'market'],
      );
      expect(month.days.first.net, {'EUR': -m(45)});
      // The transfer moves money without adding any.
      expect(month.days[1].net, {'EUR': m(3200)});
      expect(month.days[2].net, {'USD': -m(20)});
      expect(month.totals.income, {'EUR': m(3200)});
      expect(month.totals.expense, {'EUR': -m(895), 'USD': -m(20)});
    },
  );

  test('filters narrow the list by type, category, label and text', () async {
    final db = testDb();
    final repository = db.transactionsRepository;
    final wallet = await addAssetsAccount(db, 'Wallet');
    final group = await addCategoryGroup(db, 'Food');
    final groceries = await addCategory(db, 'Groceries', groupId: group);
    final work = ok(await db.labelsRepository.save(name: 'work'));
    final march = (DateTime(2026, 3), DateTime(2026, 4));

    final market = ok(
      await repository.save(
        TransactionDraft(
          type: TransactionType.expense,
          occurredAt: DateTime(2026, 3, 2, 10),
          amount: -m(40),
          assetsAccountId: wallet,
          categoryId: groceries,
          title: 'Central Market',
        ),
      ),
    );
    final salary = ok(
      await repository.save(
        TransactionDraft(
          type: TransactionType.income,
          occurredAt: DateTime(2026, 3, 1, 9),
          amount: m(3200),
          assetsAccountId: wallet,
          title: 'Salary',
          notes: 'March payslip',
          labelIds: [work],
        ),
      ),
    );

    Future<List<String>> ids(TransactionFilter filter) async => [
      for (final t
          in await repository
              .watchInRange(march.$1, march.$2, filter: filter)
              .first)
        t.id,
    ];

    expect(await ids(const TransactionFilter()), [market, salary]);
    expect(await ids(const TransactionFilter(type: TransactionType.income)), [
      salary,
    ]);
    expect(await ids(TransactionFilter(categoryId: groceries)), [market]);
    expect(await ids(TransactionFilter(labelId: work)), [salary]);
    // Titles and notes, ignoring case.
    expect(await ids(const TransactionFilter(query: 'market')), [market]);
    expect(await ids(const TransactionFilter(query: 'payslip')), [salary]);
    expect(await ids(const TransactionFilter(query: 'nothing')), isEmpty);
  });

  test('a filter counts what is on, keeps the search, and a transfer drops '
      'the category', () {
    const budget = TransactionFilter(query: 'rent', categoryGroupId: 'g');
    expect(budget.count, 1);
    // One category replaces the group a budget drilled down to.
    final category = budget.withCategory('c');
    expect((category.categoryId, category.categoryGroupId), ('c', null));
    expect(category.count, 1);

    final all = budget
        .withType(TransactionType.expense)
        .withAssetsAccount('a')
        .withLabel('l');
    expect(all.count, 4);
    expect(all.query, 'rent');
    expect(all.withQuery('rent'), all);
    expect(all.withQuery('food'), isNot(all));
    expect(all.withQuery('food').count, 4);

    final transfer = all.withType(TransactionType.transfer);
    expect(transfer.categoryGroupId, isNull);
    expect(transfer.count, 3);
    expect(all.withType(null).count, 3);
    expect(all.withLabel(null).withAssetsAccount(null).count, 2);
    expect(all.cleared(), const TransactionFilter(query: 'rent'));
  });

  test('the form drops what the new type cannot have, and swaps the sides '
      'of a transfer', () {
    final expense = TransactionFormValues(
      type: TransactionType.expense,
      assetsAccountId: 'wallet',
      toAssetsAccountId: null,
      categoryId: 'groceries',
      occurredAt: DateTime(2026, 9, 17),
      labelIds: const ['trip'],
      schedule: ReminderSchedule(
        frequency: ReminderFrequency.monthly,
        startDate: DateTime(2026, 9, 17),
        nextDueAt: DateTime(2026, 9, 17),
      ),
      autoPost: false,
      notify: false,
      refund: true,
    );
    // Nullable fields: kept unless passed, `null` included.
    expect(expense.copyWith().categoryId, 'groceries');
    expect(expense.copyWith(categoryId: null).categoryId, isNull);

    // A category belongs to one kind, and only an expense is refunded.
    final income = expense.withType(TransactionType.income);
    expect((income.categoryId, income.refund), (null, false));
    expect(income.labelIds, ['trip']);
    expect(expense.withType(TransactionType.expense).refund, isTrue);

    final transfer = expense
        .withType(TransactionType.transfer)
        .copyWith(toAssetsAccountId: 'savings');
    expect(transfer.isTransfer, isTrue);
    final swapped = transfer.swapped();
    expect(
      (swapped.assetsAccountId, swapped.toAssetsAccountId),
      ('savings', 'wallet'),
    );
    // Only a transfer has a destination.
    expect(swapped.withType(TransactionType.expense).toAssetsAccountId, isNull);
    expect(
      swapped.withType(TransactionType.transfer).toAssetsAccountId,
      'wallet',
    );
  });

  group('screens', () {
    late ProviderContainer container;
    late AppDatabase db;

    Future<void> open(WidgetTester tester, String path) async {
      container.read(routerProvider).go(path);
      await settle(tester);
    }

    Future<String> start(WidgetTester tester, {DateTime? now}) async {
      container = await pumpApp(tester, now: now);
      db = container.read(appDatabaseProvider);
      return (await tester.runAsync(
        () => addAssetsAccount(db, 'Wallet', currency: 'USD'),
      ))!;
    }

    testWidgets('the list groups the month and a long press offers Edit and '
        'Delete, which moves a row to the Trash, with Undo', (tester) async {
      final wallet = await start(tester);
      await _addToday(
        tester,
        db,
        assetsAccountId: wallet,
        title: 'Central Market',
      );
      await open(tester, Routes.transactions);

      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Net'), findsOneWidget);
      expect(find.text('Central Market'), findsOneWidget);
      expect(find.text('Uncategorized · Wallet'), findsOneWidget);

      // A swipe belongs to the tabs now.
      await tester.drag(find.text('Central Market'), const Offset(-600, 0));
      await settle(tester);
      await open(tester, Routes.transactions);
      expect(find.text('Central Market'), findsOneWidget);

      await tester.longPress(find.text('Central Market'));
      await settle(tester);
      expect(find.text('Edit'), findsOneWidget);
      // Nothing is deleted until Delete is chosen.
      expect(find.text('Moved to Trash'), findsNothing);
      await tester.tap(find.text('Delete'));
      await settle(tester);
      expect(find.text('Central Market'), findsNothing);
      expect(find.text('Moved to Trash'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Central Market'), findsOneWidget);
    });

    testWidgets('the search keeps the keyboard while typing', (tester) async {
      final wallet = await start(tester);
      await _addToday(tester, db, assetsAccountId: wallet, title: 'Bakery');
      await _addToday(tester, db, assetsAccountId: wallet, title: 'Cinema');
      await open(tester, Routes.transactions);

      final search = find.widgetWithText(TextField, 'Search title or notes');
      await tester.showKeyboard(search);
      for (final text in ['b', 'ba', 'bak']) {
        tester.testTextInput.enterText(text);
        await tester.pump();
        expect(find.byType(TextField), findsOneWidget);
        await settle(tester);
      }
      expect(tester.testTextInput.isVisible, isTrue);
      expect(find.text('Bakery'), findsOneWidget);
      expect(find.text('Cinema'), findsNothing);
    });

    testWidgets('the editor opens without the keyboard', (tester) async {
      final wallet = await start(tester);
      final id = ok(
        (await tester.runAsync(
          () => db.transactionsRepository.save(
            TransactionDraft(
              type: TransactionType.expense,
              occurredAt: DateTime.now(),
              amount: -m(3),
              assetsAccountId: wallet,
            ),
          ),
        ))!,
      );
      await open(tester, Routes.newTransaction());
      expect(tester.testTextInput.isVisible, isFalse);

      await open(tester, Routes.transaction(id));
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('a new transaction starts as income and needs a title', (
      tester,
    ) async {
      await start(tester);
      await open(tester, Routes.newTransaction());
      expect(find.text('+'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '20');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);
      expect(find.text('Enter a title'), findsOneWidget);
    });

    testWidgets('the editor saves an expense', (tester) async {
      final wallet = await start(tester);
      await open(tester, Routes.newTransaction(TransactionType.expense));

      await tester.enterText(find.byType(TextField).first, '12.50');
      await tester.enterText(find.byType(TextField).at(1), 'Bakery');
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);

      final saved = (await tester.runAsync(
        () => db.transactionsRepository
            .watchInRange(
              DateTime(2000),
              DateTime(2100),
              filter: TransactionFilter(assetsAccountId: wallet),
            )
            .first,
      ))!;
      expect(saved.single.title, 'Bakery');
      // Typed positive, saved negative: the type gives the sign.
      expect(saved.single.amount.micros, -m(12.5));
      expect(saved.single.amount.currency, 'USD');
    });

    testWidgets('a transfer without destination says so', (tester) async {
      await start(tester);
      await open(tester, Routes.newTransaction(TransactionType.transfer));

      await tester.enterText(find.byType(TextField).first, '20');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);

      expect(find.text('Choose a destination assets account'), findsOneWidget);
    });

    /// Tall enough to build the whole editor.
    void tall(WidgetTester tester) {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(800, 2400);
      addTearDown(tester.view.reset);
    }

    Future<List<Transaction>> saved(WidgetTester tester) async =>
        (await tester.runAsync(
          () => db.transactionsRepository
              .watchInRange(DateTime(2000), DateTime(2100))
              .first,
        ))!;

    testWidgets('Filters narrow the list, count on their button and are '
        'cleared from the empty result', (tester) async {
      final wallet = await start(tester);
      await tester.runAsync(() async {
        final trip = ok(await db.labelsRepository.save(name: 'trip'));
        for (final (type, title, amount, labels) in [
          (TransactionType.expense, 'Movie night', -m(9), [trip]),
          (TransactionType.income, 'Salary', m(3200), <String>[]),
        ]) {
          ok(
            await db.transactionsRepository.save(
              TransactionDraft(
                type: type,
                occurredAt: DateTime.now(),
                amount: amount,
                assetsAccountId: wallet,
                title: title,
                labelIds: labels,
              ),
            ),
          );
        }
      });
      await open(tester, Routes.transactions);
      expect(find.text('Movie night'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);

      await tester.tap(find.text('Filters'));
      await settle(tester);
      await tester.tap(find.text('Expense'));
      await settle(tester);
      await tester.tap(find.text('Apply'));
      await settle(tester);
      expect(find.text('Filters (1)'), findsOneWidget);
      expect(find.text('Movie night'), findsOneWidget);
      expect(find.text('Salary'), findsNothing);

      // The sheet opens on the filters in use and adds to them.
      await tester.tap(find.text('Filters (1)'));
      await settle(tester);
      await tester.tap(find.text('Label'));
      await settle(tester);
      await tester.tap(find.text('trip').last);
      await settle(tester);
      await tester.tap(find.text('Income').last);
      await settle(tester);
      await tester.tap(find.text('Apply'));
      await settle(tester);
      expect(find.text('Filters (2)'), findsOneWidget);
      expect(find.text('No transactions match your search'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Clear'));
      await settle(tester);
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Movie night'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
    });

    testWidgets('a transfer between currencies needs the amount received '
        'and shows its rate', (tester) async {
      final wallet = await start(tester);
      final savings = (await tester.runAsync(
        () => addAssetsAccount(db, 'Savings'),
      ))!;
      await open(tester, Routes.newTransaction(TransactionType.transfer));

      await tester.enterText(find.byType(TextField).first, '100');
      await tester.tap(find.text('To'));
      await settle(tester);
      // The source cannot be its own destination.
      expect(find.text('Wallet'), findsNothing);
      await tester.tap(find.text('Savings'));
      await settle(tester);
      expect(find.text('AMOUNT RECEIVED · EUR'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(2), 'To savings');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);
      expect(find.text('Enter the amount received'), findsOneWidget);
      expect(await saved(tester), isEmpty);

      await tester.enterText(find.byType(TextField).at(1), '90');
      await settle(tester);
      expect(find.text('1 USD = 0.90 EUR'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);

      final transfer = (await saved(tester)).single;
      expect(transfer.type, TransactionType.transfer);
      expect(transfer.assetsAccountId, wallet);
      expect(transfer.amount, const Money(100000000, 'USD'));
      expect(transfer.transfer!.assetsAccountId, savings);
      expect(transfer.transfer!.amountReceived, m(90));
    });

    testWidgets('a refund with a new label is saved, and "Save and add '
        'another" keeps the form open', (tester) async {
      tall(tester);
      await start(tester);
      await open(tester, Routes.newTransaction(TransactionType.expense));

      await tester.enterText(find.byType(TextField).first, '15');
      await tester.enterText(find.byType(TextField).at(1), 'Returned shoes');
      await tester.tap(
        find.textContaining('This is a refund', findRichText: true),
      );
      await settle(tester);
      expect(find.text('+'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).last, 'gift');
      await settle(tester);
      await tester.tap(find.text('Create “gift”'));
      await settle(tester);
      expect(find.text('Created just now'), findsOneWidget);
      await tester.tap(find.text('Done · 1 label'));
      await settle(tester);
      expect(find.text('gift'), findsOneWidget);

      await tester.tap(find.text('Save and add another'));
      await settle(tester);
      expect(find.text('Transaction saved'), findsOneWidget);
      // Still the editor, ready for the next one.
      expect(find.text('Returned shoes'), findsNothing);
      expect(find.text('gift'), findsNothing);
      expect(find.text('Save and add another'), findsOneWidget);

      final refund = (await saved(tester)).single;
      expect(refund.type, TransactionType.expense);
      expect(refund.title, 'Returned shoes');
      // An expense that adds to the assets account.
      expect(refund.amount.micros, m(15));
      final labels = (await tester.runAsync(
        () => db
            .customSelect(
              'SELECT l.name FROM transaction_labels tl '
              'JOIN labels l ON l.id = tl.label_id',
            )
            .get(),
      ))!;
      expect([for (final row in labels) row.read<String>('name')], ['gift']);
    });

    testWidgets('the date comes from a calendar and keeps the time; a '
        'future one is listed as scheduled', (tester) async {
      tall(tester);
      await start(tester, now: DateTime(2026, 9, 17, 10, 30));
      await open(tester, Routes.transactions);
      unawaited(
        container
            .read(routerProvider)
            .push(Routes.newTransaction(TransactionType.expense)),
      );
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, '850');
      await tester.enterText(find.byType(TextField).at(1), 'Rent');

      await tester.tap(find.text('Sep 17, 2026'));
      await settle(tester);
      await tester.tap(find.text('25'));
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(find.text('Sep 25, 2026'), findsOneWidget);

      // A dismissed time picker changes nothing.
      await tester.tap(find.textContaining('10:30'));
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(find.textContaining('10:30'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);
      expect(
        (await saved(tester)).single.occurredAt,
        DateTime(2026, 9, 25, 10, 30),
      );
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Scheduled'), findsWidgets);
    });

    testWidgets('the editor changes a transaction in place and deletes it '
        'to the Trash', (tester) async {
      final wallet = await start(tester);
      final id = await _addToday(
        tester,
        db,
        assetsAccountId: wallet,
        title: 'Bakery',
        amount: -3,
      );
      await open(tester, Routes.transactions);
      await tester.tap(find.text('Bakery'));
      await settle(tester);
      expect(find.text('3.00'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '4.50');
      await tester.enterText(find.byType(TextField).at(1), 'Bakery and coffee');
      await tester.tap(find.text('Save changes'));
      await settle(tester);
      expect(find.text('Bakery and coffee'), findsOneWidget);
      final changed = (await saved(tester)).single;
      expect(changed.id, id);
      // Still an expense: typed positive, kept negative.
      expect(changed.amount.micros, -m(4.5));

      await tester.tap(find.text('Bakery and coffee'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);
      expect(find.text('Moved to Trash'), findsOneWidget);
      expect(find.text('Bakery and coffee'), findsNothing);
      expect(await saved(tester), isEmpty);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Bakery and coffee'), findsOneWidget);
    });
  });
}
