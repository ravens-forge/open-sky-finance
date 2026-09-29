import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/leader_row.dart';
import '../../settings/widgets/settings_section.dart';
import '../models/technical_info.dart';

/// The technical info as labelled rows, in the order shown and copied.
Map<String, String> technicalInfoRows(
  AppLocalizations l10n,
  TechnicalInfo info,
) => {
  l10n.reportBugInfoVersion: info.versionAndBuild,
  l10n.reportBugInfoPlatform: info.platform,
  l10n.reportBugInfoLanguage: info.language,
  l10n.reportBugInfoSchema: '${info.schemaVersion}',
};

class TechnicalInfoSection extends StatelessWidget {
  const TechnicalInfoSection({
    super.key,
    required this.info,
    required this.include,
    required this.onIncludeChanged,
  });

  final TechnicalInfo? info;
  final bool include;
  final ValueChanged<bool> onIncludeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          title: l10n.reportBugInfoTitle,
          children: [
            Column(
              children: [
                if (info case final info?)
                  for (final MapEntry(:key, :value) in technicalInfoRows(
                    l10n,
                    info,
                  ).entries)
                    LeaderRow(name: key, amount: Text(value)),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.reportBugInclude),
              value: include,
              onChanged: onIncludeChanged,
            ),
          ],
        ),
        Text(l10n.reportBugNeverIncluded, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
