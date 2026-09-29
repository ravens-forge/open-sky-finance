import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../settings/widgets/settings_section.dart';
import '../models/issue_kind.dart';

class IssueKindPicker extends StatelessWidget {
  const IssueKindPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final IssueKind value;
  final ValueChanged<IssueKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    Widget option(IssueKind kind, String title, String subtitle) =>
        RadioListTile<IssueKind>(
          contentPadding: EdgeInsets.zero,
          value: kind,
          title: Text(title, style: text.rowTitle),
          subtitle: Text(subtitle, style: text.rowSubtitle),
        );
    return RadioGroup<IssueKind>(
      groupValue: value,
      onChanged: (kind) => onChanged(kind ?? value),
      child: SettingsSection(
        title: l10n.reportBugType,
        children: [
          option(
            IssueKind.bug,
            l10n.reportBugKindBug,
            l10n.reportBugKindBugHint,
          ),
          option(
            IssueKind.idea,
            l10n.reportBugKindIdea,
            l10n.reportBugKindIdeaHint,
          ),
        ],
      ),
    );
  }
}
