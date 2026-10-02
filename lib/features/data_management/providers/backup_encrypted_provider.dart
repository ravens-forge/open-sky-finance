import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/setting_keys.dart';

part 'backup_encrypted_provider.g.dart';

/// Whether new backups are encrypted with a password.
@riverpod
Stream<bool> backupEncrypted(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.backupKey)
    .map((key) => key != null);
