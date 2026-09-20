import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/database/seed.dart';
import 'package:open_sky_finance/data/database/tables/transactions_table.dart';
import 'package:open_sky_finance/data/enums/assets_account_type.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/money.dart';
import 'package:open_sky_finance/data/models/timestamps.dart';
import 'package:open_sky_finance/data/models/transaction.dart';
import 'package:open_sky_finance/data/models/transfer_destination.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';

import 'test_db.dart';

void main() {
  test('foreign keys are enforced', () async {
    final db = testDb();
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.single, 1);

    await expectLater(
      db
          .into(db.transactionLabelsTable)
          .insert(
            TransactionLabelsTableCompanion.insert(
              transactionId: 'missing',
              labelId: 'missing',
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('indexes exist', () async {
    final db = testDb();
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    expect(
      rows.map((r) => r.read<String>('name')),
      containsAll([
        'transactions_occurred_at',
        'transactions_assets_account_occurred_at',
        'transactions_to_assets_account_id',
        'transactions_category_id',
        'transactions_deleted_at',
        'categories_group_id',
        'reminders_next_due_at',
      ]),
    );
  });

  group('CHECK constraints', () {
    late AppDatabase db;
    late String a;
    late String b;
    late String food;

    setUp(() async {
      db = testDb();
      a = await addAssetsAccount(db, 'A');
      b = await addAssetsAccount(db, 'B');
      food = await addCategory(
        db,
        'Groceries',
        groupId: await addCategoryGroup(db, 'Food'),
      );
    });

    Future<void> insert({
      TransactionType type = TransactionType.transfer,
      int amount = 1,
      String? to,
      int? toAmount,
      String? categoryId,
      String currency = 'EUR',
    }) {
      final now = DateTime.now().toUtc();
      return db
          .into(db.transactionsTable)
          .insert(
            TransactionsTableCompanion.insert(
              id: '${DateTime.now().microsecondsSinceEpoch}',
              type: type,
              occurredAt: DateTime(2026, 3, 1),
              amount: amount,
              assetsAccountId: a,
              toAssetsAccountId: Value(to),
              toAmount: Value(toAmount),
              categoryId: Value(categoryId),
              currency: currency,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    final rejected = throwsA(isA<SqliteException>());

    test('accept a valid transfer', () => insert(to: b));
    test('transfer needs a destination', () => expect(insert(), rejected));
    test('transfer to itself', () => expect(insert(to: a), rejected));
    test(
      'transfer amount is positive',
      () => expect(insert(to: b, amount: -1), rejected),
    );
    test(
      'transfer has no category',
      () => expect(insert(to: b, categoryId: food), rejected),
    );
    test(
      'non-transfer has no destination',
      () => expect(insert(type: TransactionType.expense, to: b), rejected),
    );
    test(
      'non-transfer has no amount received',
      () =>
          expect(insert(type: TransactionType.expense, toAmount: 1), rejected),
    );
    test(
      'opening balance has no category',
      () => expect(
        insert(type: TransactionType.openingBalance, categoryId: food),
        rejected,
      ),
    );
    test(
      'currency is an ISO code',
      () => expect(insert(to: b, currency: 'eur'), rejected),
    );
  });

  test('rows map to and from domain objects field by field', () async {
    final db = testDb();
    final from = await addAssetsAccount(db, 'A');
    final to = await addAssetsAccount(db, 'B', currency: 'USD');
    final written = Transaction(
      id: 'id',
      type: TransactionType.transfer,
      occurredAt: DateTime(2026, 3, 14, 18, 30),
      title: 'title',
      amount: const Money(1, 'EUR'),
      assetsAccountId: from,
      transfer: TransferDestination(
        assetsAccountId: to,
        amountReceived: 2,
        exchangeRate: '2',
      ),
      categoryId: null,
      notes: 'notes',
      reminderId: null,
      deletedAt: DateTime.utc(2026, 3, 16),
      timestamps: Timestamps(
        createdAt: DateTime.utc(2026, 3, 14),
        updatedAt: DateTime.utc(2026, 3, 15),
      ),
    );
    await db
        .into(db.transactionsTable)
        .insert(TransactionTableRow.fromDomain(written).toInsertable());
    final read = (await db.transactionsRepository.findById('id'))!;

    List<Object?> fields(Transaction t) => [
      t.id,
      t.type,
      t.occurredAt,
      t.title,
      t.amount,
      t.assetsAccountId,
      t.transfer?.assetsAccountId,
      t.transfer?.amountReceived,
      t.transfer?.exchangeRate,
      t.categoryId,
      t.notes,
      t.reminderId,
      t.deletedAt,
      t.timestamps.createdAt,
      t.timestamps.updatedAt,
    ];
    expect(fields(read), fields(written));
  });

  test('occurred_at is stored as wall-clock text without offset', () async {
    final db = testDb();
    await addAssetsAccount(db, 'A', openingBalance: m(1));
    final row = await db
        .customSelect('SELECT occurred_at FROM transactions')
        .getSingle();
    expect(row.read<String>('occurred_at'), '2026-01-01T00:00:00');
  });

  test('seeds the cash assets account and category groups', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      executor: NativeDatabase.memory(),
      onCreated: (db) => seedDefaults(
        db,
        lookupAppLocalizations(const Locale('fr')),
        currency: 'EUR',
      ),
    );
    addTearDown(db.close);

    final accounts = await db.select(db.assetsAccountsTable).get();
    expect(accounts.single.name, 'Espèces');
    expect(accounts.single.type, AssetsAccountType.cash);
    expect(accounts.single.currency, 'EUR');

    final groups = await db.select(db.categoryGroupsTable).get();
    expect(groups.where((g) => g.kind == CategoryKind.expense), hasLength(7));
    expect(
      groups.where((g) => g.kind == CategoryKind.income).map((g) => g.name),
      ['Salaire', 'Autres revenus'],
      reason: 'income comes first',
    );
    expect(groups.first.kind, CategoryKind.income);

    // Every group starts with one category, so the app is usable at once.
    final categories = await db.select(db.categoriesTable).get();
    expect(categories, hasLength(groups.length));
    expect(
      {for (final c in categories) c.groupId},
      {for (final g in groups) g.id},
    );
    expect(categories.map((c) => c.name), contains('Loyer'));
    expect(await db.settingsRepository.get(SettingKeys.mainCurrency), 'EUR');
  });

  test('device currency follows the region', () {
    expect(deviceCurrency(const Locale('es', 'MX')), 'MXN');
    expect(deviceCurrency(const Locale('fr', 'FR')), 'EUR');
    expect(deviceCurrency(const Locale('en', 'US')), 'USD');
  });
}
