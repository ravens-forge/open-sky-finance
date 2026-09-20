import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/models/category.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/features/categories/models/category_group_node.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

Category _category(
  String id, {
  String? parentId,
  CategoryKind kind = CategoryKind.expense,
  bool hidden = false,
}) => Category(
  id: id,
  name: id,
  kind: kind,
  parentId: parentId,
  icon: 'category',
  color: parentId == null ? 0xFF0F5C4D : null,
  isHidden: hidden,
  sortOrder: 0,
);

void main() {
  test('groups keep their order and hidden ones can be left out', () {
    final all = [
      _category('food'),
      _category('groceries', parentId: 'food'),
      _category('sweets', parentId: 'food', hidden: true),
      _category('salary', kind: CategoryKind.income),
      _category('old', hidden: true),
      _category('forgotten', parentId: 'old'),
    ];

    final expense = groupCategories(all, CategoryKind.expense);
    expect([for (final node in expense) node.group.id], ['food', 'old']);
    expect(
      [for (final c in expense[0].categories) c.id],
      ['groceries', 'sweets'],
    );
    expect(groupCategories(all, CategoryKind.income).single.group.id, 'salary');

    final visible = groupCategories(
      all,
      CategoryKind.expense,
      includeHidden: false,
    );
    expect([for (final node in visible) node.group.id], ['food']);
    expect([for (final c in visible.single.categories) c.id], ['groceries']);
  });

  test('a category follows its group colour until it has its own', () {
    final node = CategoryGroupNode(
      group: _category('food'),
      categories: [_category('groceries', parentId: 'food')],
    );
    expect(node.colorOf(node.categories.single), 0xFF0F5C4D);
    expect(
      node.colorOf(
        Category(
          id: 'x',
          name: 'x',
          kind: CategoryKind.expense,
          parentId: 'food',
          icon: 'category',
          color: 0xFFB8391F,
          isHidden: false,
          sortOrder: 0,
        ),
      ),
      0xFFB8391F,
    );
  });

  group('screens', () {
    late ProviderContainer container;
    late AppDatabase db;

    // The page's list, not the text fields inside it.
    final page = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> open(WidgetTester tester, String path) async {
      container.read(routerProvider).go(path);
      await settle(tester);
    }

    Future<void> start(WidgetTester tester) async {
      container = await pumpApp(tester);
      db = container.read(appDatabaseProvider);
    }

    Future<String> add(
      WidgetTester tester,
      String name, {
      CategoryKind kind = CategoryKind.expense,
      String? parentId,
    }) async => (await tester.runAsync(
      () => addCategory(db, name, kind: kind, parentId: parentId),
    ))!;

    Future<String> addTransaction(
      WidgetTester tester,
      String categoryId,
    ) async {
      final account = (await tester.runAsync(
        () => addAssetsAccount(db, 'Bank'),
      ))!;
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

    testWidgets('first launch: intro and groups without categories', (
      tester,
    ) async {
      await start(tester);
      await add(tester, 'Food');
      await add(tester, 'Salary', kind: CategoryKind.income);
      await open(tester, Routes.categories);

      expect(find.text('Expenses (1)'), findsOneWidget);
      expect(find.text('Income (1)'), findsOneWidget);
      expect(find.textContaining('Your groups are ready'), findsOneWidget);
      expect(find.text('No categories yet'), findsOneWidget);
      expect(find.text('Add category to Food'), findsOneWidget);
      expect(find.text('New category group'), findsOneWidget);
    });

    testWidgets('groups expand and collapse', (tester) async {
      await start(tester);
      final food = await add(tester, 'Food');
      await add(tester, 'Groceries', parentId: food);
      await open(tester, Routes.categories);

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('1 category'), findsOneWidget);
      expect(find.textContaining('Your groups are ready'), findsNothing);

      await tester.tap(find.byTooltip('Hide the categories of Food'));
      await settle(tester);
      expect(find.text('Groceries'), findsNothing);
    });

    testWidgets('editor creates a category inside a group', (tester) async {
      await start(tester);
      final food = await add(tester, 'Food');
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

      final all = await tester.runAsync(
        () => db.categoriesRepository.watchAll().first,
      );
      final saved = all!.firstWhere((c) => c.name == 'Groceries');
      expect(saved.parentId, food);
      expect(saved.kind, CategoryKind.expense);
      // No colour of its own: it follows the group's.
      expect(saved.color, isNull);
    });

    testWidgets('group editor lists its categories and locks the type', (
      tester,
    ) async {
      await start(tester);
      final food = await add(tester, 'Food');
      await add(tester, 'Groceries', parentId: food);
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
        scrollable: page,
      );
      expect(find.text('Move or delete its category first.'), findsOneWidget);
    });

    testWidgets('delete moves the transactions of a category', (tester) async {
      await start(tester);
      final food = await add(tester, 'Food');
      final groceries = await add(tester, 'Groceries', parentId: food);
      final transaction = await addTransaction(tester, groceries);
      await open(tester, Routes.category(groceries));

      await tester.scrollUntilVisible(
        find.text('Delete category'),
        200,
        scrollable: page,
      );
      expect(find.text('1 transaction'), findsOneWidget);
      await tester.tap(find.text('Delete category'));
      await settle(tester);

      expect(
        find.text("1 transaction uses it. This can't be undone."),
        findsOneWidget,
      );
      expect(find.text('To Food'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await settle(tester);

      final saved = await tester.runAsync(
        () => db.transactionsRepository.findById(transaction),
      );
      expect(saved!.categoryId, food);
      final all = await tester.runAsync(
        () => db.categoriesRepository.watchAll().first,
      );
      expect(all!.where((c) => c.id == groceries), isEmpty);
    });

    testWidgets('the picker searches and offers the whole group', (
      tester,
    ) async {
      await start(tester);
      final food = await add(tester, 'Food');
      final groceries = await add(tester, 'Groceries', parentId: food);
      final home = await add(tester, 'Home');
      await add(tester, 'Rent', parentId: home);
      final transaction = await addTransaction(tester, groceries);
      await open(tester, Routes.category(groceries));
      await tester.scrollUntilVisible(
        find.text('Delete category'),
        200,
        scrollable: page,
      );
      await tester.tap(find.text('Delete category'));
      await settle(tester);

      await tester.tap(find.text('To another category'));
      await settle(tester);
      expect(find.text('Whole group'), findsNWidgets(2));

      await tester.enterText(
        find.widgetWithText(TextField, 'Search categories'),
        'rént',
      );
      await settle(tester);
      expect(find.text('Groceries'), findsNothing);
      await tester.tap(find.text('Rent'));
      await settle(tester);

      await tester.tap(find.text('Delete'));
      await settle(tester);
      final saved = await tester.runAsync(
        () => db.transactionsRepository.findById(transaction),
      );
      expect(saved!.categoryId, isNotNull);
      expect(saved.categoryId, isNot(groceries));
    });
  });
}
