import 'package:drift/drift.dart';

import '../../core/dates/wall_clock.dart';
import '../../core/ids.dart';
import '../../core/money/currency_converter.dart';
import '../../core/result.dart';
import '../database/app_database.dart';
import '../database/tables/transaction_labels_table.dart';
import '../database/tables/transactions_table.dart';
import '../enums/transaction_type.dart';
import '../models/transaction.dart';
import 'repository_data_error.dart';
import 'report_sql.dart';
import '../models/transaction_draft.dart';
import '../models/title_suggestion.dart';

part 'transactions_repository.g.dart';

@DriftAccessor(tables: [TransactionsTable, TransactionLabelsTable])
class TransactionsRepository extends DatabaseAccessor<AppDatabase>
    with _$TransactionsRepositoryMixin {
  TransactionsRepository(super.attachedDatabase);

  /// Rows not in the Trash: the base of every list, search and calendar query.
  SimpleSelectStatement<$TransactionsTableTable, TransactionTableRow> live() =>
      select(transactionsTable)..where((t) => t.deletedAt.isNull());

  /// Whether any transaction exists, trashed ones included.
  Future<bool> hasAny() async =>
      await (select(transactionsTable)..limit(1)).getSingleOrNull() != null;

  /// Newest first, `from <= occurred_at < to`, optionally touching one assets
  /// account (either side of a transfer).
  Stream<List<Transaction>> watchInRange(
    DateTime from,
    DateTime to, {
    String? assetsAccountId,
  }) {
    final query = live()
      ..where(
        (t) =>
            t.occurredAt.isBiggerOrEqualValue(formatWallClock(from)) &
            t.occurredAt.isSmallerThanValue(formatWallClock(to)),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.occurredAt),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    if (assetsAccountId != null) {
      query.where(
        (t) =>
            t.assetsAccountId.equals(assetsAccountId) |
            t.toAssetsAccountId.equals(assetsAccountId),
      );
    }
    return query.map((r) => r.toDomain()).watch();
  }

  /// Trashed rows included, for the editor and Restore.
  Future<Transaction?> findById(String id) => (select(
    transactionsTable,
  )..where((t) => t.id.equals(id))).map((r) => r.toDomain()).getSingleOrNull();

  Stream<List<Transaction>> watchTrash() =>
      (select(transactionsTable)
            ..where((t) => t.deletedAt.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
          .map((r) => r.toDomain())
          .watch();

  Future<List<String>> labelIdsOf(String transactionId) =>
      (select(transactionLabelsTable)
            ..where((l) => l.transactionId.equals(transactionId)))
          .map((l) => l.labelId)
          .get();

  /// Validates the invariants of DATA_MODEL, then inserts or updates the row and
  /// its labels in one database transaction. Returns the id.
  Future<Result<String, RepositoryDataError>> save(TransactionDraft draft) =>
      transaction(() async {
        final (row, error) = await _validate(draft);
        if (error != null) return Err(error);

        final now = DateTime.now().toUtc();
        final id = draft.id ?? newId();
        if (draft.id == null) {
          await into(transactionsTable).insert(
            row!.copyWith(
              id: Value(id),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        } else {
          final updated =
              await (update(transactionsTable)..where((t) => t.id.equals(id)))
                  .write(row!.copyWith(updatedAt: Value(now)));
          if (updated == 0) return const Err(RepositoryDataError.notFound);
        }

        await (delete(
          transactionLabelsTable,
        )..where((l) => l.transactionId.equals(id))).go();
        await batch(
          (b) => b.insertAll(transactionLabelsTable, [
            for (final labelId in draft.labelIds.toSet())
              TransactionLabelsTableCompanion.insert(
                transactionId: id,
                labelId: labelId,
              ),
          ]),
        );
        return Ok(id);
      });

  Future<(TransactionsTableCompanion?, RepositoryDataError?)> _validate(
    TransactionDraft d,
  ) async {
    if (d.type == TransactionType.openingBalance) {
      return (null, RepositoryDataError.invalidType);
    }
    if (d.amount == 0) return (null, RepositoryDataError.invalidAmount);

    final accounts = attachedDatabase.assetsAccountsRepository;
    final source = await accounts.findById(d.assetsAccountId);
    if (source == null) return (null, RepositoryDataError.notFound);

    int? toAmount;
    String? exchangeRate;
    if (d.type == TransactionType.transfer) {
      final to = d.toAssetsAccountId == null
          ? null
          : await accounts.findById(d.toAssetsAccountId!);
      if (to == null) return (null, RepositoryDataError.notFound);
      if (to.id == source.id) {
        return (null, RepositoryDataError.transferToSameAssetsAccount);
      }
      if (d.amount < 0) return (null, RepositoryDataError.invalidAmount);
      if (d.categoryId != null) {
        return (null, RepositoryDataError.categoryNotAllowed);
      }
      if (to.currency == source.currency) {
        if (d.toAmount != null) {
          return (null, RepositoryDataError.toAmountNotAllowed);
        }
      } else {
        toAmount = d.toAmount;
        if (toAmount == null) {
          return (null, RepositoryDataError.toAmountRequired);
        }
        if (toAmount <= 0) return (null, RepositoryDataError.invalidAmount);
        exchangeRate = rate(toAmount, d.amount).toString();
      }
    } else {
      if (d.toAssetsAccountId != null || d.toAmount != null) {
        return (null, RepositoryDataError.toAmountNotAllowed);
      }
      if (d.categoryId != null) {
        final category = await attachedDatabase.categoriesRepository.findById(
          d.categoryId!,
        );
        if (category == null) return (null, RepositoryDataError.notFound);
        if (category.kind.name != d.type.name) {
          return (null, RepositoryDataError.categoryKindMismatch);
        }
      }
    }

    return (
      TransactionsTableCompanion(
        type: Value(d.type),
        occurredAt: Value(d.occurredAt),
        title: Value(d.title.trim()),
        amount: Value(d.amount),
        assetsAccountId: Value(source.id),
        toAssetsAccountId: Value(d.toAssetsAccountId),
        toAmount: Value(toAmount),
        categoryId: Value(d.categoryId),
        currency: Value(source.currency),
        exchangeRate: Value(exchangeRate),
        notes: Value(d.notes),
        reminderId: Value(d.reminderId),
      ),
      null,
    );
  }

  Future<void> _setDeletedAt(String id, DateTime? deletedAt) =>
      (update(transactionsTable)..where((t) => t.id.equals(id))).write(
        TransactionsTableCompanion(deletedAt: Value(deletedAt)),
      );

  /// Moves the transaction to the Trash.
  Future<void> trash(String id) => _setDeletedAt(id, DateTime.now().toUtc());

  /// Undo and Restore. A deleted category leaves it uncategorized.
  Future<void> restore(String id) => _setDeletedAt(id, null);

  Future<int> deletePermanently(String id) =>
      (delete(transactionsTable)..where((t) => t.id.equals(id))).go();

  Future<int> emptyTrash() =>
      (delete(transactionsTable)..where((t) => t.deletedAt.isNotNull())).go();

  /// Transaction types per day (local date, midnight) in [from, to), for the
  /// calendar markers.
  Stream<Map<DateTime, Set<TransactionType>>> watchCalendarMarkers(
    DateTime from,
    DateTime to,
  ) =>
      customSelect(
        '''
SELECT substr(occurred_at, 1, 10) AS day, type FROM transactions
WHERE deleted_at IS NULL AND occurred_at >= ?1 AND occurred_at < ?2
GROUP BY 1, 2''',
        variables: [wallClockVariable(from), wallClockVariable(to)],
        readsFrom: {transactionsTable},
      ).watch().map((rows) {
        final days = <DateTime, Set<TransactionType>>{};
        for (final r in rows) {
          (days[DateTime.parse(r.read<String>('day'))] ??= {}).add(
            TransactionType.values.byName(r.read<String>('type')),
          );
        }
        return days;
      });

  /// Up to [limit] distinct titles starting with [prefix] (case-insensitive for
  /// ASCII), most used first, with the type, assets accounts and category of
  /// their latest use.
  Future<List<TitleSuggestion>> titleSuggestions(
    String prefix, {
    int limit = 20,
  }) async {
    final pattern =
        '${prefix.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}')}%';
    // SQLite fills the bare columns from the row holding MAX(occurred_at).
    final rows = await customSelect(
      r'''
SELECT title, type, assets_account_id, to_assets_account_id, category_id,
  COUNT(*) AS uses, MAX(occurred_at) AS last_used
FROM transactions
WHERE deleted_at IS NULL AND title <> '' AND title LIKE ?1 ESCAPE '\'
GROUP BY title ORDER BY uses DESC, last_used DESC LIMIT ?2''',
      variables: [Variable(pattern), Variable(limit)],
      readsFrom: {transactionsTable},
    ).get();
    return [
      for (final r in rows)
        TitleSuggestion(
          title: r.read<String>('title'),
          type: TransactionType.values.byName(r.read<String>('type')),
          assetsAccountId: r.read<String>('assets_account_id'),
          toAssetsAccountId: r.readNullable<String>('to_assets_account_id'),
          categoryId: r.readNullable<String>('category_id'),
          uses: r.read<int>('uses'),
        ),
    ];
  }
}
