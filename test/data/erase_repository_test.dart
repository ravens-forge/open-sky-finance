import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';

import 'test_db.dart';

/// A little of everything: two assets accounts (one opening balance), a
/// budgeted category, a labelled expense, one in the Trash, a reminder, and
/// every kind of setting.
Future<void> _fill(AppDatabase db) async {
  final bank = await addAssetsAccount(db, 'Bank', openingBalance: m(100));
  await addAssetsAccount(db, 'Wallet');
  final group = await addCategoryGroup(db, 'Food');
  final category = await addCategory(db, 'Groceries', groupId: group);
  ok(await db.budgetsRepository.set(category, m(300)));
  final label = ok(await db.labelsRepository.save(name: 'trip'));
  for (final title in ['Market', 'Bakery']) {
    final id = ok(
      await db.transactionsRepository.save(
        TransactionDraft(
          type: TransactionType.expense,
          occurredAt: DateTime(2026, 9, 1),
          amount: -m(12),
          assetsAccountId: bank,
          categoryId: category,
          title: title,
          labelIds: [label],
        ),
      ),
    );
    if (title == 'Bakery') await db.transactionsRepository.trash(id);
  }
  await addReminder(db, 'r1', assetsAccountId: bank, categoryId: category);
  for (final (key, value) in [
    (SettingKeys.themeMode, 'dark'),
    (SettingKeys.locale, 'fr'),
    (SettingKeys.firstDayOfWeek, '7'),
    (SettingKeys.mainCurrency, 'USD'),
    (SettingKeys.homeSections, '[]'),
    (SettingKeys.onboardingSeenSteps, '["welcome"]'),
    (SettingKeys.autoBackupEnabled, 'true'),
    (SettingKeys.lastBackupAt, '2026-09-10T08:00:00Z'),
  ]) {
    await db.settingsRepository.set(key, value);
  }
}

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));

  test('counts what erasing would delete', () async {
    final db = testDb();
    await _fill(db);

    final counts = await db.eraseRepository.counts();
    expect(counts.assetsAccounts, 2);
    expect(counts.transactions, 1, reason: 'no opening balance, no Trash');
    expect(counts.trashed, 1);
    expect(counts.reminders, 1);
    expect(counts.budgets, 1);
    expect(counts.labels, 1);
    expect(counts.categories, 1);
  });

  test('erase leaves only the seed data and the kept settings', () async {
    final db = testDb();
    await _fill(db);

    await db.eraseRepository.eraseAll(fr, currency: 'CHF');
    await db.eraseRepository.vacuum();

    for (final table in [
      'transactions',
      'transaction_labels',
      'labels',
      'reminders',
      'reminder_labels',
    ]) {
      expect(await _count(db, table), 0, reason: table);
    }
    final accounts = await db.select(db.assetsAccountsTable).get();
    expect(accounts.single.name, 'Espèces');
    expect(accounts.single.currency, 'CHF');
    expect(
      (await db.select(db.categoriesTable).get()).map((c) => c.name),
      isNot(contains('Groceries')),
    );
    expect((await db.eraseRepository.counts()).budgets, 0);

    final settings = {
      for (final s in await db.select(db.settingsTable).get()) s.key: s.value,
    };
    expect(settings, {
      SettingKeys.themeMode: 'dark',
      SettingKeys.locale: 'fr',
      SettingKeys.firstDayOfWeek: '7',
      // Seeded again; the onboarding sets it once more.
      SettingKeys.mainCurrency: 'CHF',
    }, reason: 'automatic backups off, onboarding and last backup reset');
  });

  test('a failed erase changes nothing', () async {
    final db = testDb();
    await _fill(db);
    // The seed fails after every row was deleted.
    await db.customStatement(
      'CREATE TRIGGER no_seed BEFORE INSERT ON assets_accounts '
      "BEGIN SELECT RAISE(ABORT, 'test'); END",
    );
    final before = await db.eraseRepository.counts();

    await expectLater(
      db.eraseRepository.eraseAll(fr, currency: 'CHF'),
      throwsA(anything),
    );

    final after = await db.eraseRepository.counts();
    expect(after.assetsAccounts, before.assetsAccounts);
    expect(after.transactions, before.transactions);
    expect(after.trashed, before.trashed);
    expect(after.budgets, before.budgets);
    expect(after.labels, before.labels);
    expect(after.reminders, before.reminders);
    expect(
      await db.settingsRepository.get(SettingKeys.autoBackupEnabled),
      'true',
    );
  });
}
