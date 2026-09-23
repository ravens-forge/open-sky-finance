import 'package:drift/drift.dart';

import '../../core/dates/wall_clock.dart';
import '../database/app_database.dart';
import '../models/app_snapshot.dart';
import '../models/current_data.dart';
import 'setting_keys.dart';

part 'backup_repository.g.dart';

@DriftAccessor()
class BackupRepository extends DatabaseAccessor<AppDatabase>
    with _$BackupRepositoryMixin {
  BackupRepository(super.attachedDatabase);

  /// Every row, read in one transaction so the copy is consistent. Assets
  /// accounts, groups and categories come by sort order then name,
  /// transactions by date, so two exports diff well.
  Future<AppSnapshot> snapshot({
    required String appVersion,
    required DateTime exportedAt,
  }) => transaction(() async {
    final db = attachedDatabase;
    final settings = await (select(
      db.settingsTable,
    )..where((s) => s.key.isIn(SettingKeys.backedUp))).get();
    return AppSnapshot(
      appVersion: appVersion,
      exportedAt: exportedAt.toUtc(),
      settings: {for (final s in settings) s.key: s.value},
      assetsAccounts:
          await (select(db.assetsAccountsTable)..orderBy([
                (a) => OrderingTerm(expression: a.sortOrder),
                (a) => OrderingTerm(expression: a.name),
                (a) => OrderingTerm(expression: a.id),
              ]))
              .get(),
      categoryGroups:
          await (select(db.categoryGroupsTable)..orderBy([
                (g) => OrderingTerm(expression: g.sortOrder),
                (g) => OrderingTerm(expression: g.name),
                (g) => OrderingTerm(expression: g.id),
              ]))
              .get(),
      categories:
          await (select(db.categoriesTable)..orderBy([
                (c) => OrderingTerm(expression: c.sortOrder),
                (c) => OrderingTerm(expression: c.name),
                (c) => OrderingTerm(expression: c.id),
              ]))
              .get(),
      labels:
          await (select(db.labelsTable)..orderBy([
                (l) => OrderingTerm(expression: l.name),
                (l) => OrderingTerm(expression: l.id),
              ]))
              .get(),
      reminders:
          await (select(db.remindersTable)..orderBy([
                (r) => OrderingTerm(expression: r.sortOrder),
                (r) => OrderingTerm(expression: r.id),
              ]))
              .get(),
      reminderLabels:
          await (select(db.reminderLabelsTable)..orderBy([
                (r) => OrderingTerm(expression: r.reminderId),
                (r) => OrderingTerm(expression: r.labelId),
              ]))
              .get(),
      transactions:
          await (select(db.transactionsTable)..orderBy([
                (t) => OrderingTerm(expression: t.occurredAt),
                (t) => OrderingTerm(expression: t.createdAt),
                (t) => OrderingTerm(expression: t.id),
              ]))
              .get(),
      transactionLabels:
          await (select(db.transactionLabelsTable)..orderBy([
                (t) => OrderingTerm(expression: t.transactionId),
                (t) => OrderingTerm(expression: t.labelId),
              ]))
              .get(),
    );
  });

  /// Replaces every row and the backed-up settings with [snapshot]; the
  /// device-only settings stay. All or nothing: on failure the data stays as
  /// it was.
  Future<void> replaceAll(AppSnapshot snapshot) => transaction(() async {
    final db = attachedDatabase;
    await db.eraseRepository.deleteFinancialRows();
    await (delete(
      db.settingsTable,
    )..where((s) => s.key.isIn(SettingKeys.backedUp))).go();
    // Parents before the rows pointing at them, for the foreign keys.
    await batch((b) {
      b
        ..insertAll(db.settingsTable, [
          for (final MapEntry(:key, :value) in snapshot.settings.entries)
            if (SettingKeys.backedUp.contains(key))
              SettingsTableCompanion.insert(key: key, value: value),
        ])
        ..insertAll(db.assetsAccountsTable, [
          for (final r in snapshot.assetsAccounts) r.toInsertable(),
        ])
        ..insertAll(db.categoryGroupsTable, [
          for (final r in snapshot.categoryGroups) r.toInsertable(),
        ])
        ..insertAll(db.categoriesTable, [
          for (final r in snapshot.categories) r.toInsertable(),
        ])
        ..insertAll(db.labelsTable, [
          for (final r in snapshot.labels) r.toInsertable(),
        ])
        ..insertAll(db.remindersTable, [
          for (final r in snapshot.reminders) r.toInsertable(),
        ])
        ..insertAll(db.reminderLabelsTable, snapshot.reminderLabels)
        ..insertAll(db.transactionsTable, [
          for (final r in snapshot.transactions) r.toInsertable(),
        ])
        ..insertAll(db.transactionLabelsTable, snapshot.transactionLabels);
    });
  });

  /// The transactions a restore of a backup made at [backupAt] would
  /// replace; the newest is taken before [before], so scheduled ones stay
  /// out.
  Future<CurrentData> currentData(
    DateTime backupAt, {
    required DateTime before,
  }) async {
    final row = await customSelect(
      '''
SELECT COUNT(*) AS n,
  MAX(CASE WHEN occurred_at < ? THEN occurred_at END) AS newest,
  COALESCE(SUM(created_at > ?), 0) AS added
FROM transactions
WHERE deleted_at IS NULL AND type <> 'openingBalance'
''',
      variables: [
        Variable(formatWallClock(before)),
        Variable(backupAt.toUtc()),
      ],
      readsFrom: {attachedDatabase.transactionsTable},
    ).getSingle();
    final newest = row.read<String?>('newest');
    return CurrentData(
      transactions: row.read('n'),
      newestTransaction: newest == null ? null : parseWallClock(newest),
      addedSince: row.read('added'),
    );
  }
}
