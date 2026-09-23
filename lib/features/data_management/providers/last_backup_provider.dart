import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/setting_keys.dart';
import '../../../services/backup/models/backup_destination.dart';
import '../models/last_backup.dart';

part 'last_backup_provider.g.dart';

/// When the last backup was made (local time), `null` when never.
@riverpod
Stream<DateTime?> lastBackup(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.lastBackupAt)
    .map((at) => at == null ? null : DateTime.tryParse(at)?.toLocal());

/// The last backup with where it went and its size, `null` when never. The
/// three settings are written in one transaction.
@riverpod
Stream<LastBackup?> lastBackupDetails(Ref ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return settings.watch(SettingKeys.lastBackupAt).asyncMap((text) async {
    final at = text == null ? null : DateTime.tryParse(text)?.toLocal();
    if (at == null) return null;
    final destination = await settings.get(SettingKeys.lastBackupDestination);
    final size = await settings.get(SettingKeys.lastBackupSize);
    return LastBackup(
      at: at,
      destination: BackupDestination.values.asNameMap()[destination],
      size: int.tryParse(size ?? ''),
    );
  });
}
