import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../services/backup/models/backup_destination.dart';
import '../models/last_backup.dart';
import 'backup_date_label.dart';
import 'file_size_label.dart';

class LastBackupHeader extends StatelessWidget {
  const LastBackupHeader({super.key, required this.last, required this.now});

  /// `null` when there is none.
  final LastBackup? last;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final last = this.last;
    final details = [
      if (last?.destination case final destination?)
        switch (destination) {
          BackupDestination.saved => l10n.backupDestinationSaved,
          BackupDestination.shared => l10n.backupDestinationShared,
        },
      if (last?.size case final size?) fileSizeLabel(l10n, size),
    ];
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            l10n.backupsLastBackup.toUpperCase(),
            style: theme.textTheme.eyebrow,
          ),
          Text(
            last == null
                ? l10n.settingsNoBackup
                : backupWhenLabel(l10n, last.at, now),
            style: theme.textTheme.headlineLarge!.copyWith(
              fontSize: 34,
              height: 1.1,
            ),
          ),
          if (details.isNotEmpty)
            Row(
              spacing: 6,
              children: [
                Icon(Icons.check, size: 16, color: scheme.onSurfaceVariant),
                Expanded(
                  child: Text(
                    details.length == 2
                        ? l10n.backupDetails(details[0], details[1])
                        : details.single,
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
