import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/data/models/category_draft.dart';
import 'package:open_sky_finance/data/models/category_group_draft.dart';
import 'package:open_sky_finance/data/models/assets_account_draft.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/assets_account_type.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/enums/home_section_id.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/transaction.dart';
import 'package:open_sky_finance/data/repositories/assets_accounts_repository.dart';
import 'package:open_sky_finance/data/repositories/categories_repository.dart';
import 'package:open_sky_finance/data/repositories/repository_data_error.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/data/models/home_section.dart';
import 'package:open_sky_finance/data/repositories/transactions_repository.dart';

import 'test_db.dart';

void main() {
  late AppDatabase db;
  late TransactionsRepository transactions;
  late String eur;
  late String eur2;
  late String usd;
  late String food;
  late String salary;
  // A transaction points at a category, never at a group.
  late String groceries;
  late String pay;

  setUp(() async {
    db = testDb();
    transactions = db.transactionsRepository;
    eur = await addAssetsAccount(db, 'Bank');
    eur2 = await addAssetsAccount(db, 'Wallet');
    usd = await addAssetsAccount(db, 'Dollars', currency: 'USD');
    food = await addCategoryGroup(db, 'Food');
    salary = await addCategoryGroup(db, 'Salary', kind: CategoryKind.income);
    groceries = await addCategory(db, 'Groceries', groupId: food);
    pay = await addCategory(db, 'Pay', groupId: salary);
  });

  TransactionDraft draft({
    String? id,
    TransactionType type = TransactionType.expense,
    int? amount,
    String? from,
    String? to,
    int? toAmount,
    String? categoryId,
    List<String> labelIds = const [],
  }) => TransactionDraft(
    id: id,
    type: type,
    occurredAt: DateTime(2026, 3, 14, 18, 30),
    amount: amount ?? (type == TransactionType.expense ? -m(10) : m(10)),
    assetsAccountId: from ?? eur,
    toAssetsAccountId: to,
    toAmount: toAmount,
    categoryId: categoryId,
    labelIds: labelIds,
  );

  Future<Transaction> row(String id) async =>
      (await db.transactionsRepository.findById(id))!;

  group('transactions', () {
    test('take the currency of their assets account', () async {
      final id = ok(await transactions.save(draft(from: usd)));
      expect((await row(id)).amount.currency, 'USD');
    });

    test('category kind must match the type', () async {
      expect(
        err(await transactions.save(draft(categoryId: pay))),
        RepositoryDataError.categoryKindMismatch,
      );
      expect(
        err(await transactions.save(draft(categoryId: groceries))),
        isNull,
      );
    });

    test('opening balances are not saved as transactions', () async {
      expect(
        err(
          await transactions.save(draft(type: TransactionType.openingBalance)),
        ),
        RepositoryDataError.invalidType,
      );
    });

    test('zero is not an amount', () async {
      expect(
        err(await transactions.save(draft(amount: 0))),
        RepositoryDataError.invalidAmount,
      );
    });

    test('non-transfers have no destination', () async {
      expect(
        err(await transactions.save(draft(to: eur2))),
        RepositoryDataError.toAmountNotAllowed,
      );
    });

    test('update keeps the id and replaces labels', () async {
      final labels = db.labelsRepository;
      final trip = ok(await labels.save(name: 'Trip'));
      final work = ok(await labels.save(name: 'Work'));
      final id = ok(await transactions.save(draft(labelIds: [trip])));
      ok(
        await transactions.save(draft(id: id, amount: -m(5), labelIds: [work])),
      );

      expect((await row(id)).amount.micros, -m(5));
      expect(await db.transactionsRepository.labelIdsOf(id), [work]);
      expect(
        err(await transactions.save(draft(id: 'missing'))),
        RepositoryDataError.notFound,
      );
    });
  });

  group('transfers', () {
    const t = TransactionType.transfer;

    test('same currency: one row, no amount received', () async {
      final id = ok(await transactions.save(draft(type: t, to: eur2)));
      final saved = await row(id);
      expect(saved.transfer?.assetsAccountId, eur2);
      expect(saved.transfer?.amountReceived, isNull);
      expect(saved.transfer?.exchangeRate, isNull);
      expect(
        err(await transactions.save(draft(type: t, to: eur2, toAmount: m(1)))),
        RepositoryDataError.toAmountNotAllowed,
      );
    });

    test('between currencies: amount received and rate', () async {
      final id = ok(
        await transactions.save(
          draft(type: t, to: usd, amount: m(100), toAmount: m(110)),
        ),
      );
      final saved = await row(id);
      expect(saved.amount.currency, 'EUR');
      expect(saved.transfer?.amountReceived, m(110));
      expect(saved.transfer?.exchangeRate, '1.1');
      expect(
        err(await transactions.save(draft(type: t, to: usd))),
        RepositoryDataError.toAmountRequired,
      );
      expect(
        err(await transactions.save(draft(type: t, to: usd, toAmount: -1))),
        RepositoryDataError.invalidAmount,
      );
    });

    test('invariants', () async {
      expect(
        err(await transactions.save(draft(type: t, to: eur))),
        RepositoryDataError.transferToSameAssetsAccount,
      );
      expect(
        err(await transactions.save(draft(type: t, to: eur2, amount: -m(1)))),
        RepositoryDataError.invalidAmount,
      );
      expect(
        err(
          await transactions.save(
            draft(type: t, to: eur2, categoryId: groceries),
          ),
        ),
        RepositoryDataError.categoryNotAllowed,
      );
      expect(
        err(await transactions.save(draft(type: t))),
        RepositoryDataError.notFound,
      );
    });
  });

  group('trash', () {
    test('trash, restore, delete permanently', () async {
      final dao = db.transactionsRepository;
      final id = ok(await transactions.save(draft()));
      final march = (DateTime(2026, 3), DateTime(2026, 4));

      await transactions.trash(id);
      expect(await dao.watchInRange(march.$1, march.$2).first, isEmpty);
      expect((await dao.watchTrash().first).single.id, id);

      await transactions.restore(id);
      expect((await dao.watchInRange(march.$1, march.$2).first).single.id, id);

      await transactions.trash(id);
      expect(await transactions.emptyTrash(), 1);
      expect(await dao.findById(id), isNull);
    });

    test('a deleted category leaves the transaction uncategorized', () async {
      final id = ok(await transactions.save(draft(categoryId: groceries)));
      await transactions.trash(id);
      ok(await db.categoriesRepository.remove(groceries));
      await transactions.restore(id);
      expect((await row(id)).categoryId, isNull);
    });
  });

  group('assets accounts', () {
    AssetsAccountsRepository repo(AppDatabase db) =>
        db.assetsAccountsRepository;

    AssetsAccountDraft account({
      String? id,
      String name = 'Savings',
      String currency = 'EUR',
      AssetsAccountType type = AssetsAccountType.bank,
      int openingBalance = 0,
      int? creditLimit,
    }) => AssetsAccountDraft(
      id: id,
      name: name,
      type: type,
      currency: currency,
      openingBalance: openingBalance,
      openingBalanceDate: DateTime(2026, 1, 1),
      creditLimit: creditLimit,
    );

    test('validation', () async {
      expect(
        err(await repo(db).save(account(name: '  '))),
        RepositoryDataError.invalidName,
      );
      expect(
        err(await repo(db).save(account(currency: 'eur'))),
        RepositoryDataError.invalidCurrency,
      );
      expect(
        err(await repo(db).save(account(creditLimit: m(500)))),
        RepositoryDataError.creditLimitNotAllowed,
      );
      final id = ok(await repo(db).save(account(name: '  Savings  ')));
      expect((await db.assetsAccountsRepository.findById(id))!.name, 'Savings');
    });

    test('opening balance is created, updated and removed', () async {
      final id = ok(await repo(db).save(account(openingBalance: m(100))));
      expect(
        (await db.assetsAccountsRepository.openingBalanceOf(id))!.amount.micros,
        m(100),
      );

      ok(await repo(db).save(account(id: id, openingBalance: -m(5))));
      expect(
        (await db.assetsAccountsRepository.openingBalanceOf(id))!.amount.micros,
        -m(5),
      );

      ok(await repo(db).save(account(id: id)));
      expect(await db.assetsAccountsRepository.openingBalanceOf(id), isNull);
    });

    test('currency is locked once there are transactions', () async {
      final id = ok(await repo(db).save(account(openingBalance: m(100))));
      // Only the opening balance: the currency can still change, with it.
      ok(
        await repo(db)
            .save(account(id: id, currency: 'GBP', openingBalance: m(100))),
      );
      expect(
        (await db.assetsAccountsRepository.openingBalanceOf(id))!
            .amount
            .currency,
        'GBP',
      );

      ok(
        await transactions.save(
          draft(
            type: TransactionType.transfer,
            from: eur,
            to: id,
            amount: m(1),
            toAmount: m(1),
          ),
        ),
      );
      expect(
        err(await repo(db).save(account(id: id, currency: 'EUR'))),
        RepositoryDataError.currencyLocked,
      );
    });

    test('favorite, hidden and order', () async {
      await repo(db).setFavorite(eur2, true);
      await repo(db).setHidden(usd, true);
      await repo(db).reorder([usd, eur2, eur]);
      final all = await repo(db).watchAll().first;
      expect([for (final a in all) a.id], [usd, eur2, eur]);
      expect(all[1].isFavorite, isTrue);
      expect(all[0].isHidden, isTrue);
      expect(
        [
          for (final a in await repo(db).watchAll(includeHidden: false).first)
            a.id,
        ],
        [eur2, eur],
      );
    });

    test('usage counts what a delete removes', () async {
      final id = ok(await repo(db).save(account(openingBalance: m(10))));
      // The opening balance is not counted.
      expect((await repo(db).usage(id)).transactions, 0);
      ok(await transactions.save(draft(from: id)));
      final trashed = ok(await transactions.save(draft(from: id)));
      await transactions.trash(trashed);
      ok(
        await transactions.save(
          draft(
            type: TransactionType.transfer,
            from: eur,
            to: id,
            amount: m(1),
          ),
        ),
      );
      final usage = await repo(db).usage(id);
      expect(usage.transactions, 3);
      expect(usage.trashed, 1);
      expect(usage.reminders, 0);
    });

    test('delete removes its transactions', () async {
      final id = ok(await transactions.save(draft(from: eur2)));
      await repo(db).remove(eur2);
      expect(await db.transactionsRepository.findById(id), isNull);
    });
  });

  group('categories', () {
    late CategoriesRepository repo;
    setUp(() => repo = db.categoriesRepository);

    test('a category takes the type of its group', () async {
      expect(await repo.kindOf(groceries), CategoryKind.expense);
      expect(
        err(
          await repo.saveCategory(
            const CategoryDraft(
              name: 'Fruit',
              groupId: 'missing',
              icon: 'category',
              color: 0xFF0F5C4D,
            ),
          ),
        ),
        RepositoryDataError.notFound,
      );
      // Moving it to a group of the other type would change what its
      // transactions are.
      expect(
        err(
          await repo.saveCategory(
            CategoryDraft(
              id: groceries,
              name: 'Groceries',
              groupId: salary,
              icon: 'category',
              color: 0xFF0F5C4D,
            ),
          ),
        ),
        RepositoryDataError.categoryKindMismatch,
      );
    });

    test('group kind is locked by its categories or transactions', () async {
      CategoryGroupDraft asIncome(String id, String name) =>
          CategoryGroupDraft(id: id, name: name, kind: CategoryKind.income);

      final empty = await addCategoryGroup(db, 'Empty');
      ok(await repo.saveGroup(asIncome(empty, 'Empty')));

      expect(
        err(await repo.saveGroup(asIncome(food, 'Food'))),
        RepositoryDataError.kindLocked,
      );
    });

    test(
      'delete: a group keeps its categories, a category reassigns',
      () async {
        expect(
          err(await repo.removeGroup(food)),
          RepositoryDataError.groupHasCategories,
        );

        final home = await addCategoryGroup(db, 'Home');
        final rent = await addCategory(db, 'Rent', groupId: home);
        final id = ok(await transactions.save(draft(categoryId: groceries)));
        expect(
          err(await repo.remove(groceries, reassignTo: pay)),
          RepositoryDataError.categoryKindMismatch,
        );
        ok(await repo.remove(groceries, reassignTo: rent));
        expect((await row(id)).categoryId, rent);
        ok(await repo.removeGroup(food));
      },
    );

    test('usage counts what a delete would move, reminders included', () async {
      ok(await transactions.save(draft(categoryId: groceries)));
      ok(await transactions.save(draft(categoryId: groceries)));
      await addReminder(db, 'r1', assetsAccountId: eur, categoryId: groceries);

      final group = await repo.groupUsage(food);
      expect(group.categories, 1, reason: 'the group holds Groceries');
      expect(group.transactions, 2);
      final usage = await repo.usage(groceries);
      expect(usage.transactions, 2);
      expect(usage.reminders, 1);
      expect(usage.hasBudget, isFalse);
      expect(usage.isUnused, isFalse);

      final rent = await addCategory(db, 'Rent', groupId: food);
      ok(await repo.remove(groceries, reassignTo: rent));
      expect(await reminderCategory(db, 'r1'), rent);
    });

    test('reorder stores the given order', () async {
      final home = await addCategoryGroup(db, 'Home');
      await repo.reorderGroups([home, salary, food]);
      final groups = await repo.watchGroups().first;
      expect([for (final g in groups) g.name], ['Home', 'Salary', 'Food']);
    });
  });

  test('label names are unique ignoring case and accents', () async {
    final labels = db.labelsRepository;
    final summer = ok(await labels.save(name: 'Été'));
    expect(
      err(await labels.save(name: 'été')),
      RepositoryDataError.duplicateName,
    );
    expect(err(await labels.save(name: ' ')), RepositoryDataError.invalidName);
    ok(await labels.save(id: summer, name: 'ÉTÉ'));
  });

  test('budgets: one per expense category, positive', () async {
    final budgets = db.budgetsRepository;
    ok(await budgets.set(food, m(100)));
    ok(await budgets.set(food, m(200)));
    expect((await db.budgetsRepository.watchAll().first).single.amount, m(200));
    expect(err(await budgets.set(food, 0)), RepositoryDataError.invalidAmount);
    expect(
      err(await budgets.set(salary, m(1))),
      RepositoryDataError.categoryKindMismatch,
    );
  });

  group('settings', () {
    test('read, write, remove', () async {
      final settings = db.settingsRepository;
      await settings.set(SettingKeys.mainCurrency, 'EUR');
      expect(await settings.get(SettingKeys.mainCurrency), 'EUR');
      await settings.set(SettingKeys.mainCurrency, null);
      expect(await settings.get(SettingKeys.mainCurrency), isNull);
    });

    test('home sections round-trip', () async {
      final settings = db.settingsRepository;
      final sections = HomeSection.listFromJson(null).reversed.toList();
      await settings.setHomeSections(sections);
      expect(await settings.watchHomeSections().first, sections);
    });

    test('home sections: defaults, unknown ids ignored, missing appended', () {
      final defaults = HomeSection.listFromJson(null);
      expect(defaults.map((s) => s.id), HomeSectionId.values);
      expect(defaults.where((s) => !s.visible).map((s) => s.id), [
        HomeSectionId.upcomingReminders,
      ]);
      expect(HomeSection.listFromJson('not json'), defaults);

      final merged = HomeSection.listFromJson(
        '[{"id":"netWorth","visible":false},{"id":"crystalBall","visible":true},'
        '{"id":"summary","visible":true},{"id":"netWorth","visible":true}]',
      );
      expect(merged.take(2), [
        HomeSection(HomeSectionId.netWorth, visible: false),
        HomeSection(HomeSectionId.summary, visible: true),
      ]);
      expect(merged.map((s) => s.id).toSet(), HomeSectionId.values.toSet());
      expect(
        merged.last,
        HomeSection(HomeSectionId.upcomingReminders, visible: false),
      );
    });
  });
}
