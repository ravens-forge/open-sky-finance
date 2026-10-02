import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../core/widgets/progress_dialog.dart';
import '../../settings/widgets/settings_row.dart';
import '../../settings/widgets/settings_section.dart';
import '../../settings/widgets/settings_switch_row.dart';
import '../providers/backup_controller.dart';
import 'backup_password_dialog.dart';

/// Encrypt backups with a password, and change it.
class BackupEncryptionSection extends ConsumerWidget {
  const BackupEncryptionSection({super.key, required this.encrypted});

  final bool encrypted;

  Future<void> _setPassword(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final password = await showBackupPasswordDialog(context);
    if (password == null || !context.mounted) return;
    final result = await withProgressDialog(
      context,
      title: l10n.backupPasswordSaving,
      body: l10n.backupPasswordSavingBody,
      task: () =>
          ref.read(backupControllerProvider.notifier).setPassword(password),
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result is Ok ? l10n.backupPasswordSet : l10n.backupPasswordFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SettingsSection(
      title: l10n.backupEncryption,
      children: [
        SettingsSwitchRow(
          icon: Icons.lock_outline,
          title: l10n.backupEncrypt,
          subtitle: l10n.backupEncryptHint,
          value: encrypted,
          onChanged: (on) => on
              ? _setPassword(context, ref)
              : ref.read(backupControllerProvider.notifier).setPassword(null),
        ),
        if (encrypted)
          SettingsRow(
            icon: Icons.key_outlined,
            title: l10n.backupPasswordChange,
            subtitle: l10n.backupPasswordChangeHint,
            action: l10n.actionChange,
            onTap: () => _setPassword(context, ref),
          ),
      ],
    );
  }
}
