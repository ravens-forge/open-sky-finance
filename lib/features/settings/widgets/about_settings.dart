import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/links.dart';
import '../providers/settings_providers.dart';
import 'settings_row.dart';
import 'settings_section.dart';

/// Privacy statement, bug reports, support, source code and version.
class AboutSettings extends ConsumerWidget {
  const AboutSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final version = ref.watch(appVersionProvider).value;
    return SettingsSection(
      title: l10n.settingsAbout,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Icon(
                Icons.lock_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              Expanded(
                child: Text(
                  l10n.settingsPrivacy,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        SettingsRow(
          icon: Icons.warning_amber_rounded,
          title: l10n.settingsReportBug,
          subtitle: l10n.settingsReportBugHint,
          onTap: () => context.push(Routes.reportBug),
        ),
        SettingsRow(
          icon: Icons.favorite_border,
          title: l10n.settingsSupport,
          subtitle: l10n.settingsSupportHint,
          onTap: () => context.push(Routes.support),
        ),
        SettingsRow(
          icon: Icons.code,
          title: l10n.settingsSource,
          subtitle: version == null ? null : l10n.settingsVersion(version),
          // The repository shows the license next to the code.
          onTap: () => launchUrl(
            Uri.parse(Links.source),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }
}
