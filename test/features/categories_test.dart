import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/models/category.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/core/widgets/destructive_button.dart';
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

/// The page's list, not the text fields inside it.
final _page = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

Future<String> _addCategory(
  WidgetTester tester,
  AppDatabase db,
  String name, {
  CategoryKind kind = CategoryKind.expense,
  String? parentId,
}) async => (await tester.runAsync(
  () => addCategory(db, name, kind: kind, parentId: parentId),
))!;

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
    }) => _addCategory(tester, db, name, kind: kind, parentId: parentId);

    Future<String> addTransaction(WidgetTester tester, String categoryId) =>
        _addTransaction(tester, db, categoryId);

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
        scrollable: _page,
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
        scrollable: _page,
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
        scrollable: _page,
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

  // Every screen of the feature in the three languages, on a phone-sized
  // surface and with the longest text there is (French, plus a long group
  // name): a row that does not fit overflows, and an overflow fails the test
  // on its own. One theme is enough, since colours change no layout.
  group('locales', () {
    final locales = [
      (
        code: 'en',
        tab: 'Expenses (1)',
        add: 'Add category to Divertissement',
        group: 'Group',
        locked: 'Locked: this group already has categories or transactions',
        where: 'Where do they go?',
      ),
      (
        code: 'es',
        tab: 'Gastos (1)',
        add: 'Añadir categoría a Divertissement',
        group: 'Grupo',
        locked: 'Bloqueado: este grupo ya tiene categorías o transacciones',
        where: '¿A dónde van?',
      ),
      (
        code: 'fr',
        tab: 'Dépenses (1)',
        add: 'Ajouter une catégorie à Divertissement',
        group: 'Groupe',
        locked:
            'Verrouillé : ce groupe a déjà des catégories ou des transactions',
        where: 'Où vont-ils ?',
      ),
    ];

    for (final l in locales) {
      testWidgets('every screen fits in ${l.code}', (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final container = await pumpApp(tester, locale: l.code);
        final db = container.read(appDatabaseProvider);
        final group = await _addCategory(tester, db, 'Divertissement');
        final category = await _addCategory(
          tester,
          db,
          'Cinéma',
          parentId: group,
        );
        await _addTransaction(tester, db, category);
        final router = container.read(routerProvider);
        Future<void> open(String path) async {
          router.go(path);
          await settle(tester);
        }

        await open(Routes.categories);
        expect(find.text(l.tab), findsOneWidget);
        expect(find.text(l.add), findsOneWidget);

        await open(Routes.newCategory(CategoryKind.expense));
        expect(find.text(l.group), findsOneWidget);

        await open(Routes.categoryGroup(group));
        expect(find.text(l.locked), findsOneWidget);

        // The delete confirmation is the tallest thing the feature shows.
        await open(Routes.category(category));
        await tester.scrollUntilVisible(
          find.byType(DestructiveButton),
          200,
          scrollable: _page,
        );
        await tester.tap(find.byType(DestructiveButton));
        await settle(tester);
        expect(find.text(l.where), findsOneWidget);
      });
    }
  });
}
