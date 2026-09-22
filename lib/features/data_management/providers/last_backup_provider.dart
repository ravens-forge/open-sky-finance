import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/setting_keys.dart';

part 'last_backup_provider.g.dart';

/// When the last backup was made (local time), `null` when never.
@riverpod
Stream<DateTime?> lastBackup(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.lastBackupAt)
    .map((at) => at == null ? null : DateTime.tryParse(at)?.toLocal());
