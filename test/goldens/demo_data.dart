import 'package:drift/drift.dart';
import 'package:open_sky_finance/core/finance_colors.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/assets_account_type.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/assets_account_draft.dart';
import 'package:open_sky_finance/data/models/category_draft.dart';
import 'package:open_sky_finance/data/models/category_group_draft.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';

import '../data/test_db.dart';

/// Ids of what [seedDemo] wrote, by name ("Visa", "Groceries", "vacation");
/// transactions under `tx:<title>`, the latest one for a repeated title.
final demo = <String, String>{};

/// Sample data in euros: six assets accounts (and a hidden one),
/// expense and income groups with their categories, six months of salary
/// and spending up to Thursday, September 17, 2026, two scheduled payments,
/// labels, budgets and three items in the Trash.
Future<void> seedDemo(AppDatabase db) async {
  demo.clear();
  await db.settingsRepository.set(SettingKeys.mainCurrency, 'EUR');

  Future<void> account(
    String name,
    AssetsAccountType type,
    num opening, {
    String currency = 'EUR',
    bool favorite = false,
    bool hidden = false,
    num? creditLimit,
  }) async => demo[name] = ok(
    await db.assetsAccountsRepository.save(
      AssetsAccountDraft(
        name: name,
        type: type,
        currency: currency,
        openingBalance: m(opening),
        openingBalanceDate: DateTime(2026, 1, 1),
        isFavorite: favorite,
        isHidden: hidden,
        creditLimit: creditLimit == null ? null : m(creditLimit),
      ),
    ),
  );
  await account('Checking', AssetsAccountType.bank, 4200, favorite: true);
  await account('Savings', AssetsAccountType.bank, 16000, favorite: true);
  await account('Travel card', AssetsAccountType.bank, 0, currency: 'USD');
  await account('Wallet', AssetsAccountType.cash, 400);
  await account(
    'Index fund',
    AssetsAccountType.investment,
    31783.28,
    favorite: true,
  );
  await account(
    'Visa',
    AssetsAccountType.creditCard,
    -569.70,
    favorite: true,
    creditLimit: 3000,
  );
  await account('Car loan', AssetsAccountType.loan, -13500);
  await account('Old savings', AssetsAccountType.bank, 0, hidden: true);

  var color = 0;
  Future<void> group(
    String name,
    Map<String, String> categories, {
    CategoryKind kind = CategoryKind.expense,
    Set<String> hidden = const {},
  }) async {
    final id = ok(
      await db.categoriesRepository.saveGroup(
        CategoryGroupDraft(name: name, kind: kind),
      ),
    );
    demo[name] = id;
    for (final MapEntry(key: category, value: icon) in categories.entries) {
      demo[category] = ok(
        await db.categoriesRepository.saveCategory(
          CategoryDraft(
            name: category,
            groupId: id,
            icon: icon,
            color: categoryColors[color++ % categoryColors.length],
            isHidden: hidden.contains(category),
          ),
        ),
      );
    }
  }

  await group('Salary', {'Monthly pay': 'payments'}, kind: CategoryKind.income);
  await group('Other income', {'Other': 'savings'}, kind: CategoryKind.income);
  await group('Housing', {
    'Rent': 'home',
    'HOA fees': 'receipt_long',
    'Maintenance': 'build',
  });
  await group('Food', {
    'Groceries': 'local_grocery_store',
    'Restaurants': 'restaurant',
  });
  await group('Transport', {
    'Fuel': 'local_gas_station',
    'Car insurance': 'directions_car',
  });
  await group('Utilities', {
    'Electricity': 'bolt',
    'Water': 'water_drop',
    'Internet': 'wifi',
  });
  await group(
    'Entertainment',
    {
      'Movies & events': 'movie',
      'Subscriptions': 'local_activity',
      'Video games': 'sports_esports',
    },
    hidden: {'Video games'},
  );
  await group('Health', {'Pharmacy': 'medication'});
  await group('Other', {});

  for (final label in ['vacation', 'car', 'work', 'gifts', 'home']) {
    demo[label] = ok(await db.labelsRepository.save(name: label));
  }

  Future<String> tx(
    DateTime date,
    String title,
    num amount, {
    required String account,
    String? category,
    String? to,
    List<String> labels = const [],
  }) async => demo['tx:$title'] = ok(
    await db.transactionsRepository.save(
      TransactionDraft(
        type: to != null
            ? TransactionType.transfer
            : amount > 0
            ? TransactionType.income
            : TransactionType.expense,
        occurredAt: date,
        amount: m(amount),
        assetsAccountId: demo[account]!,
        toAssetsAccountId: to == null ? null : demo[to],
        categoryId: category == null ? null : demo[category],
        title: title,
        labelIds: [for (final l in labels) demo[l]!],
      ),
    ),
  );

  // April to August: salary, rent, groceries, a restaurant and savings.
  final spent = [1310.0, 1880.0, 1150.0, 2520.0, 1490.0];
  for (var month = 4; month <= 8; month++) {
    final i = month - 4;
    await tx(
      DateTime(2026, month, 1, 9),
      'Salary',
      3200 + (month == 6 ? 250 : 0),
      account: 'Checking',
      category: 'Monthly pay',
      labels: ['work'],
    );
    await tx(
      DateTime(2026, month, 2, 9),
      'Rent',
      -850,
      account: 'Checking',
      category: 'Rent',
    );
    await tx(
      DateTime(2026, month, 12, 18),
      'Central Market',
      -(spent[i] - 850) * 0.7,
      account: 'Wallet',
      category: 'Groceries',
    );
    await tx(
      DateTime(2026, month, 20, 21),
      'Dinner out',
      -(spent[i] - 850) * 0.3,
      account: 'Visa',
      category: 'Restaurants',
      labels: month == 7 ? ['vacation'] : const [],
    );
    await tx(
      DateTime(2026, month, 25, 8),
      'Monthly savings',
      450,
      account: 'Checking',
      to: 'Savings',
    );
  }

  // September.
  await tx(
    DateTime(2026, 9, 1, 8),
    'Card payment',
    520,
    account: 'Checking',
    to: 'Visa',
  );
  await tx(
    DateTime(2026, 9, 2, 9),
    'Electricity',
    -92.30,
    account: 'Checking',
    category: 'Electricity',
    labels: ['home'],
  );
  await tx(
    DateTime(2026, 9, 5, 12),
    'Streaming',
    -12.99,
    account: 'Visa',
    category: 'Subscriptions',
  );
  await tx(
    DateTime(2026, 9, 13, 21),
    'La Plaza Restaurant',
    -54.20,
    account: 'Visa',
    category: 'Restaurants',
    labels: ['vacation'],
  );
  await tx(
    DateTime(2026, 9, 15, 9),
    'Salary',
    3200,
    account: 'Checking',
    category: 'Monthly pay',
    labels: ['work'],
  );
  await tx(
    DateTime(2026, 9, 15, 13),
    'Pharmacy',
    -38.90,
    account: 'Wallet',
    category: 'Pharmacy',
  );
  await tx(
    DateTime(2026, 9, 15, 19),
    'Cinema',
    -24,
    account: 'Visa',
    category: 'Movies & events',
    labels: ['gifts'],
  );
  await tx(
    DateTime(2026, 9, 15, 20),
    'Online order',
    -86.15,
    account: 'Visa',
    category: 'Groceries',
  );
  await tx(
    DateTime(2026, 9, 16, 8),
    'Monthly savings',
    450,
    account: 'Checking',
    to: 'Savings',
  );
  await tx(
    DateTime(2026, 9, 16, 17),
    'Gas station',
    -68.40,
    account: 'Visa',
    category: 'Fuel',
    labels: ['car'],
  );
  await tx(
    DateTime(2026, 9, 17, 8),
    'Bakery',
    -4.60,
    account: 'Wallet',
    category: 'Groceries',
  );
  await tx(
    DateTime(2026, 9, 17, 9),
    'Central Market',
    -42.80,
    account: 'Wallet',
    category: 'Groceries',
  );
  // Scheduled.
  await tx(
    DateTime(2026, 9, 25, 9),
    'Rent',
    -850,
    account: 'Checking',
    category: 'Rent',
  );
  await tx(
    DateTime(2026, 9, 30, 9),
    'Car insurance',
    -312.40,
    account: 'Checking',
    category: 'Car insurance',
    labels: ['car'],
  );

  for (final (category, amount) in [
    ('Rent', 850),
    ('Groceries', 400),
    ('Restaurants', 180),
    ('Fuel', 150),
    ('Electricity', 100),
    ('Subscriptions', 40),
  ]) {
    ok(await db.budgetsRepository.set(demo[category]!, m(amount)));
  }

  await addReminder(
    db,
    'phone',
    assetsAccountId: demo['Checking']!,
    title: 'Phone bill',
    nextDueAt: '2026-09-20T00:00:00',
  );

  // The Trash: one item deleted today, two on September 12.
  Future<void> trashed(String id, DateTime deletedAt) async {
    await db.transactionsRepository.trash(id);
    await (db.update(db.transactionsTable)..where((t) => t.id.equals(id)))
        .write(TransactionsTableCompanion(deletedAt: Value(deletedAt.toUtc())));
  }

  await trashed(
    await tx(
      DateTime(2026, 9, 17, 8, 30),
      'Coffee',
      -3.20,
      account: 'Wallet',
      category: 'Restaurants',
    ),
    DateTime(2026, 9, 17, 9),
  );
  await trashed(
    await tx(
      DateTime(2026, 9, 1, 9),
      'Salary (duplicate)',
      3200,
      account: 'Checking',
      category: 'Monthly pay',
    ),
    DateTime(2026, 9, 12, 20),
  );
  await trashed(
    await tx(
      DateTime(2026, 9, 10, 9),
      'Move to savings',
      100,
      account: 'Checking',
      to: 'Savings',
    ),
    DateTime(2026, 9, 12, 20, 5),
  );

  // The repositories stamp writes with the real time: fix it, so "Added …"
  // on the editor stays the same from run to run.
  final stamp = DateTime(2026, 9, 13, 21, 5).toUtc();
  await db
      .update(db.transactionsTable)
      .write(
        TransactionsTableCompanion(
          createdAt: Value(stamp),
          updatedAt: Value(stamp),
        ),
      );
}
