import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/dates/year_month.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';

import 'test_db.dart';

/// Synthetic ledger (EUR unless noted):
///
/// | date   | A (bank)       | B (cash) | U (USD) | H (hidden) |
/// | 01 Jan | opening +100   |          |         |            |
/// | 10 Mar | −30 groceries  |          |         | −7         |
/// | 15 Mar |                | +50      |         |            |
/// | 20 Mar | → B 20         | +20      |         |            |
/// | 25 Mar | → U 110        |          | +121    |            |
/// | 01 Dec | −5 (scheduled) |          |         |            |
/// plus a trashed −1000 on A in March.
void main() {
  late AppDatabase db;
  late String a, b, u, h, food, groceries, trip, idle;

  setUp(() async {
    db = testDb();
    a = await addAssetsAccount(db, 'A', openingBalance: m(100));
    b = await addAssetsAccount(db, 'B');
    u = await addAssetsAccount(db, 'U', currency: 'USD');
    h = await addAssetsAccount(db, 'H', isHidden: true);
    food = await addCategoryGroup(db, 'Food');
    groceries = await addCategory(db, 'Groceries', groupId: food);
    trip = ok(await db.labelsRepository.save(name: 'Trip'));
    idle = ok(await db.labelsRepository.save(name: 'Idle'));

    final repo = db.transactionsRepository;
    Future<String> add(
      TransactionType type,
      DateTime at,
      int amount,
      String from, {
      String? to,
      int? toAmount,
      String? categoryId,
      String title = '',
      List<String> labelIds = const [],
    }) async => ok(
      await repo.save(
        TransactionDraft(
          type: type,
          occurredAt: at,
          amount: amount,
          assetsAccountId: from,
          toAssetsAccountId: to,
          toAmount: toAmount,
          categoryId: categoryId,
          title: title,
          labelIds: labelIds,
        ),
      ),
    );

    const e = TransactionType.expense;
    const t = TransactionType.transfer;
    await add(
      e,
      DateTime(2026, 3, 10),
      -m(30),
      a,
      categoryId: groceries,
      title: 'Market',
      labelIds: [trip],
    );
    await add(e, DateTime(2026, 3, 10), -m(7), h, categoryId: groceries);
    await add(TransactionType.income, DateTime(2026, 3, 15), m(50), b);
    await add(t, DateTime(2026, 3, 20), m(20), a, to: b, labelIds: [trip]);
    await add(t, DateTime(2026, 3, 25), m(110), a, to: u, toAmount: m(121));
    await add(e, DateTime(2026, 12, 1), -m(5), a);
    final trashed = await add(
      e,
      DateTime(2026, 3, 11),
      -m(1000),
      a,
      categoryId: groceries,
      labelIds: [trip],
    );
    await repo.trash(trashed);
  });

  test('balances as of a date', () async {
    expect(await db.balancesRepository.watchBalances(DateTime(2026, 4)).first, {
      a: m(100 - 30 - 20 - 110),
      b: m(70),
      u: m(121),
      h: -m(7),
    });
    expect(
      (await db.balancesRepository
          .watchBalances(DateTime(2026, 12, 2))
          .first)[a],
      -m(65),
    );
    expect(
      (await db.balancesRepository
          .watchBalances(DateTime(2026, 1, 1))
          .first)[a],
      0,
    );
  });

  test(
    'month summary skips hidden accounts, transfers and opening balances',
    () async {
      final march = YearMonth(2026, 3);
      final summary = await db.incomeExpenseRepository
          .watchSummary(march.start, march.end)
          .first;
      expect(summary.income, {'EUR': m(50)});
      expect(summary.expense, {'EUR': -m(30)});
      expect(summary.net, {'EUR': m(20)});
    },
  );

  test(
    'cash flow per month uses favorites, or every visible account',
    () async {
      final flow = await db.incomeExpenseRepository
          .watchCashFlow(YearMonth(2026, 1), YearMonth(2026, 4))
          .first;
      expect(flow.keys, [
        YearMonth(2026, 1),
        YearMonth(2026, 2),
        YearMonth(2026, 3),
      ]);
      expect(flow[YearMonth(2026, 1)]!.income, isEmpty);
      expect(flow[YearMonth(2026, 3)]!.net, {'EUR': m(20)});

      await (db.update(db.assetsAccountsTable)..where((x) => x.id.equals(b)))
          .write(const AssetsAccountsTableCompanion(isFavorite: Value(true)));
      final favorites = await db.incomeExpenseRepository
          .watchCashFlow(YearMonth(2026, 3), YearMonth(2026, 4))
          .first;
      expect(favorites[YearMonth(2026, 3)]!.income, {'EUR': m(50)});
      expect(favorites[YearMonth(2026, 3)]!.expense, isEmpty);
    },
  );

  test('spending by category and its group', () async {
    final march = YearMonth(2026, 3);
    expect(
      await db.incomeExpenseRepository
          .watchCategoryTotals(CategoryKind.expense, march.start, march.end)
          .first,
      {
        food: {
          groceries: {'EUR': -m(30)},
        },
      },
    );
    expect(
      await db.incomeExpenseRepository
          .watchCategoryTotals(CategoryKind.income, march.start, march.end)
          .first,
      {
        null: {
          null: {'EUR': m(50)},
        },
      },
    );
  });

  test('net worth history at each month end', () async {
    final history = await db.balancesRepository
        .watchNetWorthHistory(
          YearMonth(2026, 2),
          YearMonth(2026, 12),
          before: DateTime(2026, 4),
        )
        .first;
    expect(history[YearMonth(2026, 2)], {'EUR': m(100)});
    expect(history[YearMonth(2026, 3)], {'EUR': m(10), 'USD': m(121)});
    expect(history[YearMonth(2026, 12)], {'EUR': m(10), 'USD': m(121)});

    await (db.update(
      db.assetsAccountsTable,
    )..where((x) => x.id.equals(u))).write(
      const AssetsAccountsTableCompanion(excludeFromNetWorth: Value(true)),
    );
    final excluded = await db.balancesRepository
        .watchNetWorthHistory(
          YearMonth(2026, 3),
          YearMonth(2026, 3),
          before: DateTime(2026, 4),
        )
        .first;
    expect(excluded[YearMonth(2026, 3)], {'EUR': m(10)});
  });

  test('balance history of one assets account', () async {
    final history = await db.balancesRepository
        .watchBalanceHistory(
          a,
          YearMonth(2026, 2),
          YearMonth(2026, 12),
          before: DateTime(2026, 4),
        )
        .first;
    expect(history[YearMonth(2026, 2)], m(100));
    expect(history[YearMonth(2026, 3)], -m(60));
    // The scheduled expense stays out.
    expect(history[YearMonth(2026, 12)], -m(60));
    expect(
      (await db.balancesRepository
          .watchBalanceHistory(
            u,
            YearMonth(2026, 3),
            YearMonth(2026, 3),
            before: DateTime(2027),
          )
          .first)[YearMonth(2026, 3)],
      m(121),
    );
  });

  test('budget progress includes the categories of a group', () async {
    await db.budgetsRepository.set(food, m(100));
    await db.budgetsRepository.set(groceries, m(10));
    final progress = await db.budgetsRepository
        .watchProgress(YearMonth(2026, 3))
        .first;
    final byCategory = {for (final p in progress) p.budget.targetId: p.spent};
    expect(byCategory, {
      food: {'EUR': m(30)},
      groceries: {'EUR': m(30)},
    });
    final april = await db.budgetsRepository
        .watchProgress(YearMonth(2026, 4))
        .first;
    expect(april.map((p) => p.spent), everyElement(isEmpty));
  });

  test('label totals', () async {
    final march = YearMonth(2026, 3);
    final totals = await db.labelsRepository
        .watchTotals(march.start, march.end)
        .first;
    expect(totals.map((t) => t.label.id), [idle, trip]);
    expect(totals.map((t) => t.count), [0, 2]);
    expect(totals.map((t) => t.total), [
      isEmpty,
      {'EUR': -m(30)},
    ]);
  });

  test('calendar markers', () async {
    final march = YearMonth(2026, 3);
    expect(
      await db.transactionsRepository
          .watchCalendarMarkers(march.start, march.end)
          .first,
      {
        DateTime(2026, 3, 10): {TransactionType.expense},
        DateTime(2026, 3, 15): {TransactionType.income},
        DateTime(2026, 3, 20): {TransactionType.transfer},
        DateTime(2026, 3, 25): {TransactionType.transfer},
      },
    );
  });

  test('title autocomplete: prefix, most used, latest category', () async {
    final repo = db.transactionsRepository;
    ok(
      await repo.save(
        TransactionDraft(
          type: TransactionType.expense,
          occurredAt: DateTime(2026, 3, 1),
          amount: -m(1),
          assetsAccountId: b,
          title: 'Market',
        ),
      ),
    );
    ok(
      await repo.save(
        TransactionDraft(
          type: TransactionType.expense,
          occurredAt: DateTime(2026, 3, 2),
          amount: -m(1),
          assetsAccountId: b,
          title: '100%_off',
        ),
      ),
    );

    final suggestions = await db.transactionsRepository.titleSuggestions('mar');
    expect(suggestions.single.title, 'Market');
    expect(suggestions.single.uses, 2);
    expect(suggestions.single.assetsAccountId, a);
    expect(suggestions.single.categoryId, groceries);

    expect(
      (await db.transactionsRepository.titleSuggestions('100%_')).single.title,
      '100%_off',
    );
    expect(await db.transactionsRepository.titleSuggestions('100__'), isEmpty);
  });

  test('rates come from the latest transfer with the main currency', () async {
    expect(
      await db.exchangeRatesRepository
          .watchRates('EUR', DateTime(2026, 3, 25))
          .first,
      isEmpty,
    );
    expect(
      (await db.exchangeRatesRepository
              .watchRates('EUR', DateTime(2026, 4))
              .first)['USD']!
          .toStringAsFixed(6),
      '0.909091',
    );
    expect(
      await db.exchangeRatesRepository
          .watchRates('USD', DateTime(2026, 4))
          .first,
      {'EUR': Decimal.parse('1.1')},
    );
  });
}
