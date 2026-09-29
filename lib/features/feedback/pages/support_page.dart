import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/links.dart';
import '../../../core/open_link.dart';
import '../../../core/widgets/info_note.dart';
import '../../settings/widgets/settings_row.dart';
import '../../settings/widgets/settings_section.dart';
import '../widgets/donate_row.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    void open(String link) => openLink(context, Uri.parse(link));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pageSupport)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${l10n.supportTitle} '),
                  TextSpan(
                    text: l10n.supportTitleEmphasis,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              style: theme.textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.supportIntro,
            style: theme.textTheme.bodyLarge!.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          // Apple requires In-App Purchase for tips, so iOS shows only the
          // other ways to help.
          if (defaultTargetPlatform != TargetPlatform.iOS)
            SettingsSection(
              title: l10n.supportDonate,
              children: [DonateRow(onTap: () => open(Links.support))],
            ),
          SettingsSection(
            title: l10n.supportOtherWays,
            children: [
              SettingsRow(
                icon: Icons.star_border,
                title: l10n.supportStar,
                subtitle: l10n.supportStarHint,
                trailingIcon: Icons.open_in_new,
                onTap: () => open(Links.source),
              ),
              SettingsRow(
                icon: Icons.language,
                title: l10n.supportTranslate,
                subtitle: l10n.supportTranslateHint,
                trailingIcon: Icons.open_in_new,
                onTap: () => open(Links.translate),
              ),
              SettingsRow(
                icon: Icons.feed_outlined,
                title: l10n.supportReport,
                subtitle: l10n.supportReportHint,
                onTap: () => context.push(Routes.reportBug),
              ),
            ],
          ),
          const SizedBox(height: 18),
          InfoNote(l10n.supportLinksNote, icon: Icons.lock_outline),
        ],
      ),
    );
  }
}
