import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/money.dart';
import 'package:open_sky_finance/data/models/timestamps.dart';
import 'package:open_sky_finance/data/models/transaction.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/models/transaction_filter.dart';
import 'package:open_sky_finance/data/providers.dart';
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

  group('screens', () {
    late ProviderContainer container;
    late AppDatabase db;

    Future<void> open(WidgetTester tester, String path) async {
      container.read(routerProvider).go(path);
      await settle(tester);
    }

    Future<String> start(WidgetTester tester) async {
      container = await pumpApp(tester);
      db = container.read(appDatabaseProvider);
      return (await tester.runAsync(
        () => addAssetsAccount(db, 'Wallet', currency: 'USD'),
      ))!;
    }

    testWidgets('the list groups the month and swiping moves a row to the '
        'Trash, with Undo', (tester) async {
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

      await tester.drag(find.text('Central Market'), const Offset(-600, 0));
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

    testWidgets('the editor saves an expense', (tester) async {
      final wallet = await start(tester);
      await open(tester, Routes.newTransaction());

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
      await open(tester, Routes.newTransaction());

      await tester.tap(find.textContaining('Transfer'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, '20');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);

      expect(find.text('Choose a destination assets account'), findsOneWidget);
    });
  });
}
