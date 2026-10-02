import 'package:flutter/foundation.dart';

import '../../../data/repositories/setting_keys.dart';
import 'auto_backup_frequency.dart';
import 'backup_folder.dart';

/// Automatic backups as set up on this device.
@immutable
class AutoBackupSettings {
  const AutoBackupSettings({
    this.enabled = false,
    this.folder,
    this.frequency = AutoBackupFrequency.weekly,
    this.keep = defaultKeep,
    this.paused = false,
  });

  /// From the `settings` rows of [keys].
  factory AutoBackupSettings.fromSettings(Map<String, String> values) {
    final ref = values[SettingKeys.autoBackupFolder];
    return AutoBackupSettings(
      enabled: values[SettingKeys.autoBackupEnabled] == 'true',
      folder: ref == null
          ? null
          : BackupFolder(
              ref: ref,
              name: values[SettingKeys.autoBackupFolderName] ?? '',
            ),
      frequency:
          AutoBackupFrequency.values
              .asNameMap()[values[SettingKeys.autoBackupFrequency]] ??
          AutoBackupFrequency.weekly,
      keep:
          int.tryParse(values[SettingKeys.autoBackupKeep] ?? '') ?? defaultKeep,
      paused: values[SettingKeys.autoBackupPaused] == 'true',
    );
  }

  static const defaultKeep = 10;

  /// The choices offered for [keep].
  static const keepOptions = [3, 5, 10, 20, 50];

  static const keys = [
    SettingKeys.autoBackupEnabled,
    SettingKeys.autoBackupFolder,
    SettingKeys.autoBackupFolderName,
    SettingKeys.autoBackupFrequency,
    SettingKeys.autoBackupKeep,
    SettingKeys.autoBackupPaused,
  ];

  final bool enabled;

  /// Kept while turned off, so turning on again needs no new pick.
  final BackupFolder? folder;
  final AutoBackupFrequency frequency;

  /// How many automatic backups the folder keeps.
  final int keep;

  /// The folder could not be reached: nothing runs until one is picked again.
  final bool paused;
}
