import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging.dart';
import '../../core/result.dart';
import '../../data/models/app_snapshot.dart';
import '../../data/providers.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/setting_keys.dart';
import '../../data/repositories/settings_repository.dart';
import 'backup_codec.dart';
import 'backup_folders.dart';
import 'models/backup_destination.dart';
import 'models/backup_file.dart';
import 'models/loaded_backup.dart';
import 'models/restore_error.dart';

part 'backup_service.g.dart';

/// Backup files: export, the copies kept in the app's private folders, and
/// restore. The save dialog and the share sheet stay with the caller.
class BackupService {
  BackupService({
    required this.backups,
    required this.settings,
    required this.safetyFolder,
    required this.shareFolder,
  });

  final BackupRepository backups;
  final SettingsRepository settings;

  /// Copies of the data made before a restore; the newest
  /// [keptSafetyBackups] stay.
  final Directory safetyFolder;

  /// Files handed to the share sheet, deleted once it closes.
  final Directory shareFolder;

  /// Larger files are rejected before they are read.
  static const maxSize = 200 * 1024 * 1024;
  static const keptSafetyBackups = 3;
  static const _prefix = 'open-sky-finance-backup-';

  /// `open-sky-finance-backup-YYYYMMDD-HHmmss.json`, in local time.
  static String fileName(DateTime at) {
    final l = at.toLocal();
    String two(int n) => '$n'.padLeft(2, '0');
    return '$_prefix${l.year}${two(l.month)}${two(l.day)}'
        '-${two(l.hour)}${two(l.minute)}${two(l.second)}.json';
  }

  /// Every row, read in one transaction and encoded in the background.
  Future<BackupFile> export({required String appVersion, DateTime? now}) async {
    final at = now ?? DateTime.now();
    final snapshot = await backups.snapshot(
      appVersion: appVersion,
      exportedAt: at,
    );
    final bytes = await Isolate.run(() => BackupCodec.encode(snapshot));
    return BackupFile(name: fileName(at), bytes: bytes);
  }

  /// Remembers when, where and how big the last backup was.
  Future<void> record(
    BackupFile file,
    BackupDestination destination, {
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toUtc();
    await settings.transaction(() async {
      await settings.set(SettingKeys.lastBackupAt, at.toIso8601String());
      await settings.set(SettingKeys.lastBackupDestination, destination.name);
      await settings.set(SettingKeys.lastBackupSize, '${file.bytes.length}');
    });
  }

  /// Writes [file] where the share sheet can read it.
  Future<File> writeShareCopy(BackupFile file) async {
    await shareFolder.create(recursive: true);
    return File('${shareFolder.path}${Platform.pathSeparator}${file.name}')
        .writeAsBytes(file.bytes, flush: true);
  }

  /// Deletes the files written for the share sheet: after sharing, and at
  /// start in case the app was killed meanwhile.
  Future<void> deleteShareCopies() async {
    if (await shareFolder.exists()) await shareFolder.delete(recursive: true);
  }

  /// Reads and checks a picked file of [size] bytes (`null` when unknown)
  /// in the background. [read] is not called for files over [maxSize].
  Future<Result<LoadedBackup, RestoreError>> load({
    required String fileName,
    required int? size,
    required Future<Uint8List> Function() read,
  }) async {
    if (size != null && size > maxSize) return const Err(RestoreFileTooLarge());
    final Uint8List bytes;
    try {
      bytes = await read();
    } on IOException catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(RestoreFailed());
    }
    if (bytes.length > maxSize) return const Err(RestoreFileTooLarge());
    final decoded = await Isolate.run(() => BackupCodec.decode(bytes));
    return switch (decoded) {
      Ok(value: final snapshot) => Ok(
        LoadedBackup(
          fileName: fileName,
          size: bytes.length,
          snapshot: snapshot,
        ),
      ),
      Err(:final error) => Err(error),
    };
  }

  /// Saves a safety backup of the current data, then replaces it with
  /// [snapshot] in one transaction. On any failure the data is untouched.
  Future<Result<void, RestoreError>> restore(
    AppSnapshot snapshot, {
    required String appVersion,
    DateTime? now,
  }) async {
    try {
      await _writeSafetyBackup(await export(appVersion: appVersion, now: now));
      await backups.replaceAll(snapshot);
      return const Ok(null);
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(RestoreFailed());
    }
  }

  Future<void> _writeSafetyBackup(BackupFile file) async {
    await safetyFolder.create(recursive: true);
    await File('${safetyFolder.path}${Platform.pathSeparator}${file.name}')
        .writeAsBytes(file.bytes, flush: true);
    // The names sort by date.
    final old = [
      for (final entity in safetyFolder.listSync())
        if (entity is File && entity.uri.pathSegments.last.startsWith(_prefix))
          entity,
    ]..sort((a, b) => b.path.compareTo(a.path));
    for (final file in old.skip(keptSafetyBackups)) {
      await file.delete();
    }
  }
}

@Riverpod(keepAlive: true)
Future<BackupService> backupService(Ref ref) async {
  final folders = await ref.watch(backupCopyFoldersProvider.future);
  return BackupService(
    backups: ref.watch(backupRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    safetyFolder: folders[0],
    shareFolder: folders[1],
  );
}
