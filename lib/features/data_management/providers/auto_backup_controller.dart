import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/now.dart';
import '../../../core/logging.dart';
import '../../../data/providers.dart';
import '../../../services/backup/auto_backup_service.dart';
import '../../../services/backup/models/auto_backup_frequency.dart';
import '../../../services/backup/models/auto_backup_result.dart';
import '../../../services/backup/models/auto_backup_settings.dart';
import '../../../services/backup/models/backup_folder.dart';
import '../../../services/backup/models/backup_folder_unreachable.dart';
import '../../settings/providers/settings_providers.dart';

part 'auto_backup_controller.g.dart';

/// Folder, frequency and keep count of automatic backups; runs the due
/// backup when the app is opened or left.
@Riverpod(keepAlive: true)
class AutoBackupController extends _$AutoBackupController {
  var _running = false;

  @override
  Stream<AutoBackupSettings> build() => ref
      .watch(settingsRepositoryProvider)
      .watchAll(AutoBackupSettings.keys)
      .map(AutoBackupSettings.fromSettings);

  /// The settings as stored now: [future] waits for a listener, and none
  /// may watch this while the app starts.
  Future<AutoBackupSettings> read() async => AutoBackupSettings.fromSettings(
    await ref
        .read(settingsRepositoryProvider)
        .watchAll(AutoBackupSettings.keys)
        .first,
  );

  Future<AutoBackupService> get _service =>
      ref.read(autoBackupServiceProvider.future);

  /// Turns automatic backups on and makes one now. Without a usable folder
  /// it asks for one first: `null` when that was cancelled.
  Future<AutoBackupResult?> turnOn() async {
    final service = await _service;
    final settings = await service.read();
    if (settings.folder == null || settings.paused) return chooseFolder();
    await service.setEnabled(true);
    return _run(force: true);
  }

  Future<void> turnOff() async => (await _service).setEnabled(false);

  /// The system folder picker, then a backup into the new folder; `null`
  /// when cancelled.
  Future<AutoBackupResult?> chooseFolder() async {
    final service = await _service;
    final BackupFolder? folder;
    try {
      folder = await service.folders.pick();
    } on BackupFolderUnreachable {
      return AutoBackupResult.paused;
    }
    if (folder == null) return null;
    await service.useFolder(folder);
    return _run(force: true);
  }

  Future<void> setFrequency(AutoBackupFrequency frequency) async =>
      (await _service).setFrequency(frequency);

  Future<void> setKeep(int keep) async => (await _service).setKeep(keep);

  /// Makes the backup if one is due; nothing when one is being made.
  Future<AutoBackupResult> runIfDue() => _run();

  Future<AutoBackupResult> _run({bool force = false}) async {
    if (_running) return AutoBackupResult.notDue;
    // Most starts: nothing to do, and no need to open the backup service.
    // (Forced runs follow a write the stream may not show yet.)
    if (!force &&
        !AutoBackupService.isDue(
          await read(),
          await AutoBackupService.lastBackupAt(
            ref.read(settingsRepositoryProvider),
          ),
          ref.read(nowProvider),
        )) {
      return AutoBackupResult.notDue;
    }
    _running = true;
    try {
      return await (await _service).run(
        appVersion: await ref.read(appVersionProvider.future),
        now: ref.read(nowProvider),
        force: force,
      );
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return AutoBackupResult.failed;
    } finally {
      _running = false;
    }
  }
}
