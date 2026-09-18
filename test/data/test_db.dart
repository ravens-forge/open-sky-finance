import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/data/models/category_draft.dart';
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

Future<String> addCategory(
  AppDatabase db,
  String name, {
  CategoryKind kind = CategoryKind.expense,
  String? parentId,
}) async => ok(
  await db.categoriesRepository.save(
    CategoryDraft(
      name: name,
      kind: kind,
      parentId: parentId,
      icon: 'category',
      color: parentId == null ? 0xFF0F5C4D : null,
    ),
  ),
);
