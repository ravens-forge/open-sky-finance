import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers.dart';
import '../../data/repositories/setting_keys.dart';
import '../../data/repositories/settings_repository.dart';
import 'backup_folder_access.dart';
import 'backup_service.dart';
import 'models/auto_backup_frequency.dart';
import 'models/auto_backup_result.dart';
import 'models/auto_backup_settings.dart';
import 'models/backup_destination.dart';
import 'models/backup_folder.dart';
import 'models/backup_folder_unreachable.dart';

part 'auto_backup_service.g.dart';

/// Automatic backups: a backup file written into a folder the user granted
/// when the last backup is older than the frequency, keeping the newest
/// ones. Its settings belong to the device: never in a backup file.
class AutoBackupService {
  AutoBackupService({
    required this.backups,
    required this.settings,
    required this.folders,
  });

  final BackupService backups;
  final SettingsRepository settings;
  final BackupFolderAccess folders;

  /// The only files of the folder it ever deletes: the ones it writes.
  static final _ownFile = RegExp(
    r'^open-sky-finance-backup-\d{8}-\d{6}\.json$',
  );

  Stream<AutoBackupSettings> watch() => settings
      .watchAll(AutoBackupSettings.keys)
      .map(AutoBackupSettings.fromSettings);

  Future<AutoBackupSettings> read() => watch().first;

  /// Writes a backup into the folder when automatic backups are on and the
  /// last backup (of any kind) is older than the frequency, or whatever its
  /// age when [force]. Then deletes the oldest of its files beyond the
  /// "keep" count. An unreachable folder pauses automatic backups.
  Future<AutoBackupResult> run({
    required String appVersion,
    DateTime? now,
    bool force = false,
  }) async {
    final s = await read();
    final folder = s.folder;
    if (!s.enabled || s.paused || folder == null) return AutoBackupResult.off;
    final at = now ?? DateTime.now();
    if (!force && !isDue(s, await lastBackupAt(settings), at)) {
      return AutoBackupResult.notDue;
    }
    final file = await backups.export(appVersion: appVersion, now: at);
    try {
      await folders.write(folder.ref, file.name, file.bytes);
      await backups.record(file, BackupDestination.automatic, now: at);
      // The names sort by date.
      final own = (await folders.list(
        folder.ref,
      )).where(_ownFile.hasMatch).toList()..sort((a, b) => b.compareTo(a));
      for (final name in own.skip(s.keep)) {
        await folders.delete(folder.ref, name);
      }
      return AutoBackupResult.done;
    } on BackupFolderUnreachable {
      await settings.set(SettingKeys.autoBackupPaused, 'true');
      return AutoBackupResult.paused;
    }
  }

  /// Whether [s] has a backup to make at [now], the last backup (of any
  /// kind) made at [last].
  static bool isDue(AutoBackupSettings s, DateTime? last, DateTime now) =>
      s.enabled &&
      !s.paused &&
      s.folder != null &&
      (last == null || !now.isBefore(s.frequency.next(last)));

  /// Local time of the last backup, `null` when never.
  static Future<DateTime?> lastBackupAt(SettingsRepository settings) async =>
      DateTime.tryParse(await settings.get(SettingKeys.lastBackupAt) ?? '')
          ?.toLocal();

  /// Automatic backups on, into [folder]; the folder before is released.
  Future<void> useFolder(BackupFolder folder) async {
    final before = (await read()).folder;
    await settings.transaction(() async {
      await settings.set(SettingKeys.autoBackupFolder, folder.ref);
      await settings.set(SettingKeys.autoBackupFolderName, folder.name);
      await settings.set(SettingKeys.autoBackupEnabled, 'true');
      await settings.set(SettingKeys.autoBackupPaused, null);
    });
    if (before != null && before.ref != folder.ref) await release(before.ref);
  }

  Future<void> setEnabled(bool enabled) =>
      settings.set(SettingKeys.autoBackupEnabled, enabled ? 'true' : null);

  Future<void> setFrequency(AutoBackupFrequency frequency) =>
      settings.set(SettingKeys.autoBackupFrequency, frequency.name);

  Future<void> setKeep(int keep) =>
      settings.set(SettingKeys.autoBackupKeep, '$keep');

  /// Gives a folder's permission back; it may be gone already.
  Future<void> release(String ref) async {
    try {
      await folders.release(ref);
    } on Object {
      // Nothing left to give back.
    }
  }
}

@Riverpod(keepAlive: true)
Future<AutoBackupService> autoBackupService(Ref ref) async => AutoBackupService(
  backups: await ref.watch(backupServiceProvider.future),
  settings: ref.watch(settingsRepositoryProvider),
  folders: ref.watch(backupFolderAccessProvider),
);
