import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../data/models/category_usage.dart';

/// What already uses the category, shown while editing one.
class CategoryUsageNote extends StatelessWidget {
  const CategoryUsageNote(this.usage, {super.key});

  final CategoryUsage usage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(l10n.categoryUsage.toUpperCase(), style: theme.textTheme.eyebrow),
        Text(
          [
            l10n.categoryUsageTransactions(usage.transactions),
            if (usage.reminders > 0)
              l10n.categoryUsageReminders(usage.reminders),
            if (usage.hasBudget) l10n.categoryUsageBudget,
          ].join(' · '),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
