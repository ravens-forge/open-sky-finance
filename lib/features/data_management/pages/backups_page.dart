import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/now.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/warning_banner.dart';
import '../../settings/widgets/settings_row.dart';
import '../../settings/widgets/settings_section.dart';
import '../providers/last_backup_provider.dart';
import '../widgets/back_up_flow.dart';
import '../widgets/last_backup_header.dart';
import '../widgets/restore_backup_flow.dart';

class BackupsPage extends ConsumerWidget {
  const BackupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pageBackups)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          LastBackupHeader(
            last: ref.watch(lastBackupDetailsProvider).value,
            now: ref.watch(nowProvider),
          ),
          const SizedBox(height: 16),
          WarningBanner(
            lead: l10n.backupsNotEncryptedLead,
            text: l10n.backupsNotEncryptedBody,
          ),
          SettingsSection(
            title: l10n.backupsBackUpNow,
            children: [
              SettingsRow(
                icon: Icons.folder_outlined,
                title: l10n.backupsSaveTo,
                subtitle: l10n.backupsSaveToHint,
                onTap: () => saveBackup(context, ref),
              ),
              Builder(
                builder: (row) => SettingsRow(
                  icon: Icons.share_outlined,
                  title: l10n.backupsShare,
                  subtitle: l10n.backupsShareHint,
                  onTap: () => shareBackup(row, ref),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: l10n.backupsRestore,
            children: [
              SettingsRow(
                icon: Icons.upload_outlined,
                title: l10n.backupsRestoreFromFile,
                subtitle: l10n.backupsRestoreFromFileHint,
                onTap: () => restoreFromFile(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
