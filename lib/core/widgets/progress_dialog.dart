import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../finance_colors.dart';
import '../l10n.dart';

class ProgressDialog extends StatelessWidget {
  const ProgressDialog({
    super.key,
    required this.title,
    required this.body,
    this.count,
    this.progress,
    this.onCancel,
  });

  final String title;
  final String body;

  /// What is being processed, e.g. "Transactions · 1,240 of 3,210".
  final String? count;

  /// 0–1, or `null` for a task that cannot tell how far it is.
  final double? progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = progress == null
        ? null
        : NumberFormat.percentPattern(context.localeName).format(progress);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: FinanceColors.of(context).sunken,
              semanticsLabel: title,
              semanticsValue: percent,
            ),
            if (count != null || percent != null) ...[
              const SizedBox(height: 8),
              DefaultTextStyle.merge(
                style: theme.textTheme.bodySmall,
                child: Row(
                  children: [
                    Expanded(child: Text(count ?? '')),
                    if (percent != null) Text(percent),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: Text(context.l10n.actionCancel),
            ),
        ],
      ),
    );
  }
}
