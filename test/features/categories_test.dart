import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/widgets/destructive_button.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/category.dart';
import 'package:open_sky_finance/data/models/category_group.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/features/categories/models/category_group_node.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

/// The page's list, not the text fields inside it.
final _page = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

CategoryGroup _group(
  String id, {
  CategoryKind kind = CategoryKind.expense,
  bool hidden = false,
}) =>
    CategoryGroup(id: id, name: id, kind: kind, isHidden: hidden, sortOrder: 0);

Category _category(String id, String groupId, {bool hidden = false}) =>
    Category(
      id: id,
      name: id,
      groupId: groupId,
      icon: 'category',
      color: 0xFF0F5C4D,
      isHidden: hidden,
      sortOrder: 0,
    );

Future<String> _addGroup(
  WidgetTester tester,
  AppDatabase db,
  String name, {
  CategoryKind kind = CategoryKind.expense,
}) async =>
    (await tester.runAsync(() => addCategoryGroup(db, name, kind: kind)))!;

Future<String> _addCategory(
  WidgetTester tester,
  AppDatabase db,
  String name, {
  required String groupId,
}) async =>
    (await tester.runAsync(() => addCategory(db, name, groupId: groupId)))!;

/// An expense in [categoryId], so it counts as usage.
Future<String> _addTransaction(
  WidgetTester tester,
  AppDatabase db,
  String categoryId,
) async {
  final account = (await tester.runAsync(() => addAssetsAccount(db, 'Bank')))!;
  return (await tester.runAsync(
    () async => ok(
      await db.transactionsRepository.save(
        TransactionDraft(
          type: TransactionType.expense,
          occurredAt: DateTime(2026, 3, 1),
          amount: -m(10),
          assetsAccountId: account,
          categoryId: categoryId,
        ),
      ),
    ),
  ))!;
}

void main() {
  test('groups keep their order and hidden ones can be left out', () {
    final groups = [
      _group('food'),
      _group('salary', kind: CategoryKind.income),
      _group('old', hidden: true),
    ];
    final categories = [
      _category('groceries', 'food'),
      _category('sweets', 'food', hidden: true),
      _category('forgotten', 'old'),
    ];

    final expense = groupCategories(groups, categories, CategoryKind.expense);
    expect([for (final node in expense) node.group.id], ['food', 'old']);
    expect(
      [for (final c in expense[0].categories) c.id],
      ['groceries', 'sweets'],
    );
    expect(
      groupCategories(groups, categories, CategoryKind.income).single.group.id,
      'salary',
    );

    final visible = groupCategories(
      groups,
      categories,
      CategoryKind.expense,
      includeHidden: false,
    );
    expect([for (final node in visible) node.group.id], ['food']);
    expect([for (final c in visible.single.categories) c.id], ['groceries']);
  });

  group('screens', () {
    late ProviderContainer container;
    late AppDatabase db;

    Future<void> open(WidgetTester tester, String path) async {
      container.read(routerProvider).go(path);
      await settle(tester);
    }

    Future<void> start(WidgetTester tester) async {
      container = await pumpApp(tester);
      db = container.read(appDatabaseProvider);
    }

    testWidgets('income comes first and a group can be collapsed', (
      tester,
    ) async {
      await start(tester);
      final food = await _addGroup(tester, db, 'Food');
      await _addCategory(tester, db, 'Groceries', groupId: food);
      await _addGroup(tester, db, 'Salary', kind: CategoryKind.income);
      await open(tester, Routes.categories);

      // The selector opens on Income, which is the first option.
      expect(find.text('Income · 1'), findsOneWidget);
      expect(find.text('Expenses · 1'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);

      await tester.tap(find.text('Expenses · 1'));
      await settle(tester);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('1 category'), findsOneWidget);
      expect(find.text('Add category to Food'), findsOneWidget);

      await tester.tap(find.byTooltip('Hide the categories of Food'));
      await settle(tester);
      expect(find.text('Groceries'), findsNothing);
    });

    testWidgets('a group without categories says so', (tester) async {
      await start(tester);
      await _addGroup(tester, db, 'Food');
      await open(tester, Routes.categories);
      await tester.tap(find.text('Expenses · 1'));
      await settle(tester);

      expect(find.text('No categories yet'), findsOneWidget);
      expect(find.text('New category group'), findsOneWidget);
    });

    testWidgets('editor creates a category inside a group', (tester) async {
      await start(tester);
      final food = await _addGroup(tester, db, 'Food');
      await open(tester, Routes.newCategory(CategoryKind.expense));

      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'Groceries',
      );
      await tester.tap(find.text('Choose a group'));
      await settle(tester);
      await tester.tap(find.text('Food'));
      await settle(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);

      final saved = await tester.runAsync(
        () => db.categoriesRepository.watchCategories().first,
      );
      expect(saved!.single.name, 'Groceries');
      expect(saved.single.groupId, food);
    });

    testWidgets('group editor lists its categories and locks the type', (
      tester,
    ) async {
      await start(tester);
      final food = await _addGroup(tester, db, 'Food');
      await _addCategory(tester, db, 'Groceries', groupId: food);
      await open(tester, Routes.categoryGroup(food));

      expect(find.text('CATEGORIES'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(
        find.text('Locked: this group already has categories or transactions'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Delete group'),
        200,
        scrollable: _page,
      );
      expect(find.text('Move or delete its category first.'), findsOneWidget);
    });

    testWidgets('delete moves the transactions of a category', (tester) async {
      await start(tester);
      final food = await _addGroup(tester, db, 'Food');
      final groceries = await _addCategory(
        tester,
        db,
        'Groceries',
        groupId: food,
      );
      final rent = await _addCategory(tester, db, 'Rent', groupId: food);
      final transaction = await _addTransaction(tester, db, groceries);
      await open(tester, Routes.category(groceries));

      await tester.scrollUntilVisible(
        find.byType(DestructiveButton),
        200,
        scrollable: _page,
      );
      expect(find.text('1 transaction'), findsOneWidget);
      await tester.tap(find.byType(DestructiveButton));
      await settle(tester);

      expect(
        find.text("1 transaction uses it. This can't be undone."),
        findsOneWidget,
      );
      // A group is not a choice any more: it moves to another category,
      // picked in the sheet ("To another category" is already selected).
      expect(find.text('To another category'), findsOneWidget);
      await tester.tap(find.text('Choose…'));
      await settle(tester);
      await tester.tap(find.text('Rent'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);

      final saved = await tester.runAsync(
        () => db.transactionsRepository.findById(transaction),
      );
      expect(saved!.categoryId, rent);
    });

    testWidgets('the picker searches and lists groups as headings', (
      tester,
    ) async {
      await start(tester);
      final food = await _addGroup(tester, db, 'Food');
      final groceries = await _addCategory(
        tester,
        db,
        'Groceries',
        groupId: food,
      );
      final fun = await _addGroup(tester, db, 'Divertissement');
      await _addCategory(tester, db, 'Cinéma', groupId: fun);
      await _addTransaction(tester, db, groceries);
      await open(tester, Routes.category(groceries));
      await tester.scrollUntilVisible(
        find.byType(DestructiveButton),
        200,
        scrollable: _page,
      );
      await tester.tap(find.byType(DestructiveButton));
      await settle(tester);
      await tester.tap(find.text('Choose…'));
      await settle(tester);

      // Groups are headings, in capitals, and the category being deleted is
      // not on offer.
      expect(find.text('DIVERTISSEMENT'), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, 'Search groups and categories'),
        'cinema',
      );
      await settle(tester);
      expect(find.text('Cinéma'), findsOneWidget);
    });
  });
}
