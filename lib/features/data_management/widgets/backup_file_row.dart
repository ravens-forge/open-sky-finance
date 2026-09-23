import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';

class BackupFileRow extends StatelessWidget {
  const BackupFileRow({
    super.key,
    required this.name,
    required this.subtitle,
    required this.onChange,
  });

  final String name;
  final String subtitle;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        spacing: 14,
        children: [
          Icon(
            Icons.description_outlined,
            size: 22,
            color: FinanceColors.of(context).muted,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(name, style: theme.textTheme.rowTitle),
                Text(subtitle, style: theme.textTheme.rowSubtitle),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: Text(context.l10n.restoreChangeFile),
          ),
        ],
      ),
    );
  }
}
