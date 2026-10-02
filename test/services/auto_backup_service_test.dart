import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/services/backup/auto_backup_service.dart';
import 'package:open_sky_finance/services/backup/backup_service.dart';
import 'package:open_sky_finance/services/backup/models/auto_backup_frequency.dart';
import 'package:open_sky_finance/services/backup/models/auto_backup_result.dart';
import 'package:open_sky_finance/services/backup/models/backup_folder.dart';

import '../data/test_db.dart';
import 'fake_backup_folder.dart';

const _drive = BackupFolder(ref: 'content://tree/1', name: 'Drive › Backups');

(AppDatabase, AutoBackupService, FakeBackupFolder) _setUp() {
  final db = testDb();
  final dir = Directory.systemTemp.createTempSync('auto_backup_test');
  addTearDown(() => dir.deleteSync(recursive: true));
  final folder = FakeBackupFolder();
  return (
    db,
    AutoBackupService(
      backups: BackupService(
        backups: db.backupRepository,
        settings: db.settingsRepository,
        safetyFolder: Directory('${dir.path}/safety'),
        shareFolder: Directory('${dir.path}/share'),
      ),
      settings: db.settingsRepository,
      folders: folder,
    ),
    folder,
  );
}

void main() {
  test('next due date per frequency, months clamped', () {
    final at = DateTime(2026, 1, 31, 9);
    expect(AutoBackupFrequency.daily.next(at), DateTime(2026, 2, 1, 9));
    expect(AutoBackupFrequency.weekly.next(at), DateTime(2026, 2, 7, 9));
    expect(AutoBackupFrequency.monthly.next(at), DateTime(2026, 2, 28, 9));
    expect(
      AutoBackupFrequency.monthly.next(DateTime(2026, 3, 15)),
      DateTime(2026, 4, 15),
    );
  });

  test('does nothing while off', () async {
    final (_, service, folder) = _setUp();
    expect(
      await service.run(appVersion: '1', now: DateTime(2026, 9, 17)),
      AutoBackupResult.off,
    );
    expect(folder.files, isEmpty);
  });

  test('writes when due, records it and waits for the frequency', () async {
    final (db, service, folder) = _setUp();
    await service.useFolder(_drive);
    final first = DateTime(2026, 9, 17, 10);
    expect(
      await service.run(appVersion: '1', now: first),
      AutoBackupResult.done,
    );
    expect(folder.files.keys, ['open-sky-finance-backup-20260917-100000.json']);
    expect(
      await db.settingsRepository.get(SettingKeys.lastBackupDestination),
      'automatic',
    );
    // Weekly by default.
    expect(
      await service.run(
        appVersion: '1',
        now: first.add(const Duration(days: 6)),
      ),
      AutoBackupResult.notDue,
    );
    expect(
      await service.run(
        appVersion: '1',
        now: first.add(const Duration(days: 7)),
      ),
      AutoBackupResult.done,
    );
    expect(folder.files, hasLength(2));
  });

  test('keeps the newest N of its own files and nothing else', () async {
    final (_, service, folder) = _setUp();
    folder.files['notes.txt'] = Uint8List(1);
    folder.files['open-sky-finance-backup-20200101-000000 (1).json'] =
        Uint8List(1);
    await service.useFolder(_drive);
    await service.setKeep(3);
    for (var day = 1; day <= 5; day++) {
      await service.run(
        appVersion: '1',
        now: DateTime(2026, 9, day, 8),
        force: true,
      );
    }
    expect(folder.files.keys.toSet(), {
      'notes.txt',
      'open-sky-finance-backup-20200101-000000 (1).json',
      'open-sky-finance-backup-20260903-080000.json',
      'open-sky-finance-backup-20260904-080000.json',
      'open-sky-finance-backup-20260905-080000.json',
    });
  });

  test('an unreachable folder pauses until a folder is chosen', () async {
    final (_, service, folder) = _setUp();
    await service.useFolder(_drive);
    folder.reachable = false;
    final now = DateTime(2026, 9, 17);
    expect(
      await service.run(appVersion: '1', now: now),
      AutoBackupResult.paused,
    );
    expect((await service.read()).paused, isTrue);
    folder.reachable = true;
    expect(await service.run(appVersion: '1', now: now), AutoBackupResult.off);

    const other = BackupFolder(ref: 'content://tree/2', name: 'Files');
    await service.useFolder(other);
    expect((await service.read()).paused, isFalse);
    expect(folder.released, [_drive.ref]);
    expect(await service.run(appVersion: '1', now: now), AutoBackupResult.done);
  });
}
