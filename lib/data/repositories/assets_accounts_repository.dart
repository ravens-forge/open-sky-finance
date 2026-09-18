import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/result.dart';
import '../database/app_database.dart';
import '../database/tables/assets_accounts_table.dart';
import '../database/tables/transactions_table.dart';
import '../enums/assets_account_type.dart';
import '../enums/transaction_type.dart';
import '../models/assets_account.dart';
import '../models/transaction.dart';
import 'repository_data_error.dart';
import 'valid_name.dart';
import '../models/assets_account_draft.dart';

part 'assets_accounts_repository.g.dart';

final _currencyCode = RegExp(r'^[A-Z]{3}$');

@DriftAccessor(tables: [AssetsAccountsTable, TransactionsTable])
class AssetsAccountsRepository extends DatabaseAccessor<AppDatabase>
    with _$AssetsAccountsRepositoryMixin {
  AssetsAccountsRepository(super.attachedDatabase);

  Stream<List<AssetsAccount>> watchAll({bool includeHidden = true}) {
    final query = select(assetsAccountsTable)
      ..orderBy([(a) => OrderingTerm(expression: a.sortOrder)]);
    if (!includeHidden) query.where((a) => a.isHidden.not());
    return query.map((r) => r.toDomain()).watch();
  }

  Future<AssetsAccount?> findById(String id) => (select(
    assetsAccountsTable,
  )..where((a) => a.id.equals(id))).map((r) => r.toDomain()).getSingleOrNull();

  /// Transactions touching [id] other than its opening balance, trashed ones
  /// included: they fix its currency.
  Future<int> countTransactions(String id) async {
    final count = transactionsTable.id.count();
    final query = selectOnly(transactionsTable)
      ..addColumns([count])
      ..where(
        (transactionsTable.assetsAccountId.equals(id) |
                transactionsTable.toAssetsAccountId.equals(id)) &
            transactionsTable.type
                .equalsValue(TransactionType.openingBalance)
                .not(),
      );
    return (await query.getSingle()).read(count)!;
  }

  Future<Transaction?> openingBalanceOf(String id) =>
      (select(transactionsTable)..where(
            (t) =>
                t.assetsAccountId.equals(id) &
                t.type.equalsValue(TransactionType.openingBalance),
          ))
          .map((r) => r.toDomain())
          .getSingleOrNull();

  /// Saves the assets account and its opening balance transaction in one
  /// database transaction. Returns the id.
  Future<Result<String, RepositoryDataError>> save(AssetsAccountDraft d) =>
      transaction(() async {
        final name = validName(d.name);
        if (name == null) return const Err(RepositoryDataError.invalidName);
        if (!_currencyCode.hasMatch(d.currency)) {
          return const Err(RepositoryDataError.invalidCurrency);
        }
        if (d.creditLimit != null) {
          if (d.type != AssetsAccountType.creditCard) {
            return const Err(RepositoryDataError.creditLimitNotAllowed);
          }
          if (d.creditLimit! < 0) {
            return const Err(RepositoryDataError.invalidAmount);
          }
        }

        final now = DateTime.now().toUtc();
        final row = AssetsAccountsTableCompanion(
          name: Value(name),
          type: Value(d.type),
          currency: Value(d.currency),
          isHidden: Value(d.isHidden),
          isFavorite: Value(d.isFavorite),
          excludeFromNetWorth: Value(d.excludeFromNetWorth),
          creditLimit: Value(d.creditLimit),
          notes: Value(d.notes),
          updatedAt: Value(now),
        );

        final id = d.id ?? newId();
        if (d.id == null) {
          final last = assetsAccountsTable.sortOrder.max();
          final sortOrder = await (selectOnly(
            assetsAccountsTable,
          )..addColumns([last])).map((r) => r.read(last)).getSingle();
          await into(assetsAccountsTable).insert(
            row.copyWith(
              id: Value(id),
              sortOrder: Value((sortOrder ?? -1) + 1),
              createdAt: Value(now),
            ),
          );
        } else {
          final existing = await findById(id);
          if (existing == null) return const Err(RepositoryDataError.notFound);
          if (existing.currency != d.currency &&
              await countTransactions(id) > 0) {
            return const Err(RepositoryDataError.currencyLocked);
          }
          await (update(
            assetsAccountsTable,
          )..where((a) => a.id.equals(id))).write(row);
        }

        await _saveOpeningBalance(id, d, now);
        return Ok(id);
      });

  Future<void> _saveOpeningBalance(
    String id,
    AssetsAccountDraft d,
    DateTime now,
  ) async {
    final existing = await openingBalanceOf(id);
    if (d.openingBalance == 0) {
      if (existing != null) {
        await (delete(
          transactionsTable,
        )..where((t) => t.id.equals(existing.id))).go();
      }
      return;
    }
    final row = TransactionsTableCompanion(
      type: const Value(TransactionType.openingBalance),
      occurredAt: Value(d.openingBalanceDate),
      amount: Value(d.openingBalance),
      assetsAccountId: Value(id),
      currency: Value(d.currency),
      updatedAt: Value(now),
    );
    if (existing == null) {
      await into(transactionsTable)
          .insert(row.copyWith(id: Value(newId()), createdAt: Value(now)));
    } else {
      await (update(
        transactionsTable,
      )..where((t) => t.id.equals(existing.id))).write(row);
    }
  }

  /// Deletes the assets account and, permanently, every transaction and reminder
  /// touching it (foreign keys cascade).
  Future<void> remove(String id) =>
      (delete(assetsAccountsTable)..where((a) => a.id.equals(id))).go();
}
