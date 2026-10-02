import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/info_note.dart';
import '../../../core/widgets/info_tooltip.dart';
import '../../../services/backup/models/auto_backup_frequency.dart';
import '../../../services/backup/models/auto_backup_settings.dart';
import '../../settings/widgets/settings_row.dart';
import '../../settings/widgets/settings_section.dart';
import '../../settings/widgets/settings_switch_row.dart';
import '../providers/auto_backup_controller.dart';
import 'auto_backup_flow.dart';

/// The switch, then the folder, frequency and keep count while it is on.
class AutoBackupSection extends ConsumerWidget {
  const AutoBackupSection({super.key, required this.settings});

  final AutoBackupSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(autoBackupControllerProvider.notifier);
    final s = settings;
    final folder = s.folder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          title: l10n.autoBackupTitle,
          info: InfoTooltip(
            label: l10n.autoBackupInfoLabel,
            eyebrow: l10n.autoBackupTitle,
            text: l10n.autoBackupInfo,
          ),
          children: [
            SettingsSwitchRow(
              icon: Icons.sync,
              title: l10n.autoBackupTitle,
              subtitle: l10n.autoBackupHint,
              value: s.enabled,
              onChanged: (on) =>
                  on ? turnOnAutoBackups(context, ref) : controller.turnOff(),
            ),
            if (s.enabled && folder != null) ...[
              SettingsRow(
                icon: Icons.cloud_outlined,
                title: l10n.autoBackupFolder,
                subtitle: folder.name,
                action: s.paused
                    ? l10n.autoBackupChooseFolder
                    : l10n.actionChange,
                onTap: () => chooseAutoBackupFolder(context, ref),
              ),
              SettingsRow(
                icon: Icons.calendar_today_outlined,
                title: l10n.autoBackupFrequency,
                subtitle: s.frequency.label(l10n),
                action: l10n.actionChange,
                onTap: () async {
                  final picked = await showChoiceSheet(
                    context,
                    title: l10n.autoBackupFrequency,
                    options: [
                      for (final f in AutoBackupFrequency.values)
                        (f, f.label(l10n)),
                    ],
                    selected: s.frequency,
                  );
                  if (picked != null) await controller.setFrequency(picked);
                },
              ),
              SettingsRow(
                icon: Icons.grid_view,
                title: l10n.autoBackupKeep,
                subtitle: l10n.autoBackupKeepHint(s.keep),
                action: l10n.actionChange,
                onTap: () async {
                  final picked = await showChoiceSheet(
                    context,
                    title: l10n.autoBackupKeep,
                    options: [
                      for (final n in AutoBackupSettings.keepOptions)
                        (n, l10n.autoBackupKeepOption(n)),
                    ],
                    selected: s.keep,
                  );
                  if (picked != null) await controller.setKeep(picked);
                },
              ),
            ],
          ],
        ),
        if (s.enabled) ...[
          const SizedBox(height: 8),
          InfoNote(l10n.autoBackupNote, icon: Icons.lock_outline),
        ],
      ],
    );
  }
}
