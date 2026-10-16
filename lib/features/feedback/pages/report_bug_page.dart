import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/links.dart';
import '../../../core/open_link.dart';
import '../../../core/widgets/warning_banner.dart';
import '../models/issue_kind.dart';
import '../providers/technical_info_provider.dart';
import '../widgets/issue_kind_picker.dart';
import '../widgets/report_bug_actions.dart';
import '../widgets/technical_info_section.dart';

class ReportBugPage extends HookConsumerWidget {
  const ReportBugPage({super.key});

  Future<void> _copy(BuildContext context, Map<String, String> rows) async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = context.l10n.reportBugCopied;
    await Clipboard.setData(
      ClipboardData(
        text: [for (final r in rows.entries) '${r.key}: ${r.value}'].join('\n'),
      ),
    );
    messenger.showSnackBar(SnackBar(content: Text(copied)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final kind = useState(IssueKind.bug);
    final include = useState(true);
    final info = ref.watch(technicalInfoProvider(l10n.localeName)).value;
    final shared = include.value ? info : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionReportBug)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text(
            l10n.reportBugIntro,
            style: theme.textTheme.bodyLarge!.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          IssueKindPicker(
            value: kind.value,
            onChanged: (value) => kind.value = value,
          ),
          TechnicalInfoSection(
            info: info,
            include: include.value,
            onIncludeChanged: (on) => include.value = on,
          ),
          const SizedBox(height: 18),
          WarningBanner(
            lead: l10n.reportBugPublicLead,
            text: l10n.reportBugPublicText,
          ),
        ],
      ),
      bottomNavigationBar: ReportBugActions(
        onCopy: shared == null
            ? null
            : () => _copy(context, technicalInfoRows(l10n, shared)),
        onOpen: () => openLink(
          context,
          Links.issueForm(kind.value.form, shared?.formFields ?? const {}),
        ),
      ),
    );
  }
}
