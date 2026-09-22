import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/data/models/category_draft.dart';
import 'package:open_sky_finance/data/models/category_group_draft.dart';
import 'package:open_sky_finance/data/models/assets_account_draft.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/assets_account_type.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/repositories/repository_data_error.dart';

/// A fresh in-memory database, closed after the test.
AppDatabase testDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(executor: NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

/// Micro-units of [units].
int m(num units) => (units * 1000000).round();

T ok<T>(Result<T, RepositoryDataError> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('expected Ok, got $error'),
};

RepositoryDataError? err(Result<Object?, RepositoryDataError> result) =>
    switch (result) {
      Ok() => null,
      Err(:final error) => error,
    };

Future<String> addAssetsAccount(
  AppDatabase db,
  String name, {
  String currency = 'EUR',
  AssetsAccountType type = AssetsAccountType.bank,
  int openingBalance = 0,
  bool isHidden = false,
  bool excludeFromNetWorth = false,
}) async => ok(
  await db.assetsAccountsRepository.save(
    AssetsAccountDraft(
      name: name,
      type: type,
      currency: currency,
      openingBalance: openingBalance,
      openingBalanceDate: DateTime(2026, 1, 1),
      isHidden: isHidden,
      excludeFromNetWorth: excludeFromNetWorth,
    ),
  ),
);

/// A minimal reminder row. The reminders repository has no writes yet, so
/// tests that need one write it directly.
Future<void> addReminder(
  AppDatabase db,
  String id, {
  required String assetsAccountId,
  String? categoryId,
  String title = '',
  String? nextDueAt,
  bool isPaused = false,
}) => db.customStatement(
  'INSERT INTO reminders (id, type, title, amount, assets_account_id, '
  'category_id, currency, frequency, start_date, next_due_at, is_paused, '
  'created_at, updated_at) '
  "VALUES (?, 'expense', ?, -1000000, ?, ?, 'EUR', 'monthly', "
  "'2026-01-01T00:00:00', ?, ?, '2026-01-01T00:00:00', '2026-01-01T00:00:00')",
  [id, title, assetsAccountId, categoryId, nextDueAt, if (isPaused) 1 else 0],
);

/// The category a reminder written by [addReminder] points at.
Future<String?> reminderCategory(AppDatabase db, String id) async =>
    (await db
            .customSelect(
              'SELECT category_id FROM reminders WHERE id = ?',
              variables: [Variable(id)],
            )
            .getSingle())
        .read<String?>('category_id');

Future<String> addCategoryGroup(
  AppDatabase db,
  String name, {
  CategoryKind kind = CategoryKind.expense,
}) async => ok(
  await db.categoriesRepository.saveGroup(
    CategoryGroupDraft(name: name, kind: kind),
  ),
);

Future<String> addCategory(
  AppDatabase db,
  String name, {
  required String groupId,
  int color = 0xFF0F5C4D,
}) async => ok(
  await db.categoriesRepository.saveCategory(
    CategoryDraft(name: name, groupId: groupId, icon: 'category', color: color),
  ),
);
