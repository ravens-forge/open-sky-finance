import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/database/tables/transactions_table.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/app_snapshot.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/services/backup/backup_codec.dart';
import 'package:open_sky_finance/services/backup/backup_service.dart';
import 'package:open_sky_finance/services/backup/models/backup_destination.dart';
import 'package:open_sky_finance/services/backup/models/loaded_backup.dart';
import 'package:open_sky_finance/services/backup/models/restore_error.dart';

import '../data/test_db.dart';

final _fixture = File('test/fixtures/backup/v1_sample.json');

(AppDatabase, BackupService, Directory) _setUp() {
  final db = testDb();
  final dir = Directory.systemTemp.createTempSync('backup_test');
  addTearDown(() => dir.deleteSync(recursive: true));
  return (
    db,
    BackupService(
      backups: db.backupRepository,
      settings: db.settingsRepository,
      safetyFolder: Directory('${dir.path}/safety'),
      shareFolder: Directory('${dir.path}/share'),
    ),
    dir,
  );
}

Future<LoadedBackup> _loadFixture(BackupService service) async {
  final bytes = _fixture.readAsBytesSync();
  final loaded = await service.load(
    fileName: 'sample.json',
    size: bytes.length,
    read: () async => bytes,
  );
  return (loaded as Ok<LoadedBackup, RestoreError>).value;
}

void main() {
  test('names files by local date and time', () {
    expect(
      BackupService.fileName(DateTime(2026, 9, 17, 10, 30, 5)),
      'open-sky-finance-backup-20260917-103005.json',
    );
  });

  test('export records nothing until the file is delivered', () async {
    final (db, service, _) = _setUp();
    await addAssetsAccount(db, 'Bank');
    final file = await service.export(appVersion: '1.0.0');
    expect(await db.settingsRepository.get(SettingKeys.lastBackupAt), isNull);
    await service.record(
      file,
      BackupDestination.shared,
      now: DateTime.utc(2026, 9, 17, 8),
    );
    expect(
      await db.settingsRepository.get(SettingKeys.lastBackupAt),
      '2026-09-17T08:00:00.000Z',
    );
    expect(
      await db.settingsRepository.get(SettingKeys.lastBackupDestination),
      'shared',
    );
    expect(
      await db.settingsRepository.get(SettingKeys.lastBackupSize),
      '${file.bytes.length}',
    );
  });

  test('share copies go away', () async {
    final (_, service, _) = _setUp();
    final copy = await service.writeShareCopy(
      await service.export(appVersion: '1.0.0'),
    );
    expect(copy.existsSync(), isTrue);
    await service.deleteShareCopies();
    expect(copy.existsSync(), isFalse);
    // Nothing to delete is fine too.
    await service.deleteShareCopies();
  });

  test('files over the size limit are never read', () async {
    final (_, service, _) = _setUp();
    var read = false;
    final result = await service.load(
      fileName: 'huge.json',
      size: BackupService.maxSize + 1,
      read: () async {
        read = true;
        return Uint8List(0);
      },
    );
    expect(read, isFalse);
    expect(
      result,
      isA<Err<LoadedBackup, RestoreError>>().having(
        (e) => e.error,
        'error',
        isA<RestoreFileTooLarge>(),
      ),
    );
  });

  test('restore saves a safety backup first and keeps the last 3', () async {
    final (db, service, dir) = _setUp();
    await addAssetsAccount(db, 'Mine');
    final backup = await _loadFixture(service);
    for (var i = 0; i < 5; i++) {
      final result = await service.restore(
        backup.snapshot,
        appVersion: '1.0.0',
        now: DateTime(2026, 9, 17, 10, i),
      );
      expect(result, isA<Ok<void, RestoreError>>());
    }
    final safety = Directory('${dir.path}/safety')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .toList()
      ..sort();
    expect(safety, [
      'open-sky-finance-backup-20260917-100200.json',
      'open-sky-finance-backup-20260917-100300.json',
      'open-sky-finance-backup-20260917-100400.json',
    ]);
    // The first safety backup held the data from before.
    final names = await db
        .select(db.assetsAccountsTable)
        .map((a) => a.name)
        .get();
    expect(names, isNot(contains('Mine')));
    expect(names, contains('Main bank'));
  });

  test('a failed restore leaves the data as it was', () async {
    final (db, service, _) = _setUp();
    final bank = await addAssetsAccount(db, 'Mine');
    final good = (await _loadFixture(service)).snapshot;
    // Past the checks, as a bug would be: a transaction of a missing account.
    final bad = AppSnapshot(
      appVersion: good.appVersion,
      exportedAt: good.exportedAt,
      settings: good.settings,
      assetsAccounts: good.assetsAccounts,
      categoryGroups: good.categoryGroups,
      categories: good.categories,
      labels: good.labels,
      reminders: good.reminders,
      reminderLabels: good.reminderLabels,
      transactions: [
        ...good.transactions,
        TransactionTableRow(
          id: 'orphan',
          type: TransactionType.income,
          occurredAt: DateTime(2026, 9, 1),
          title: '',
          amount: 1,
          assetsAccountId: 'missing',
          toAssetsAccountId: null,
          toAmount: null,
          categoryId: null,
          currency: 'EUR',
          exchangeRate: null,
          notes: '',
          reminderId: null,
          deletedAt: null,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      ],
      transactionLabels: good.transactionLabels,
    );
    final result = await service.restore(bad, appVersion: '1.0.0');
    expect(
      result,
      isA<Err<void, RestoreError>>().having(
        (e) => e.error,
        'error',
        isA<RestoreFailed>(),
      ),
    );
    final ids = await db.select(db.assetsAccountsTable).map((a) => a.id).get();
    expect(ids, [bank]);
  });

  test('the preview compares with what would be lost', () async {
    final (db, service, _) = _setUp();
    final bank = await addAssetsAccount(db, 'Mine');
    await db.customStatement(
      "INSERT INTO transactions (id, type, occurred_at, amount, "
      "assets_account_id, currency, created_at, updated_at) VALUES "
      "('t1', 'expense', '2026-09-15T10:00:00', -1000000, ?, 'EUR', "
      "'2026-09-15T10:00:00.000Z', '2026-09-15T10:00:00.000Z')",
      [bank],
    );
    final backup = await _loadFixture(service);
    final current = await db.backupRepository.currentData(
      backup.snapshot.exportedAt,
    );
    expect(current.transactions, 1);
    expect(current.addedSince, 1);
    expect(current.newestTransaction, DateTime(2026, 9, 15, 10));
    expect(backup.snapshot.counts.assetsAccounts, 4);
    expect(BackupCodec.format, 'open-sky-finance-backup');
  });
}
