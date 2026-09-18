import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../finance_colors.dart';
import '../l10n.dart';

class ProgressDialog extends StatelessWidget {
  const ProgressDialog({
    super.key,
    required this.title,
    required this.body,
    required this.count,
    required this.progress,
    this.onCancel,
  });

  final String title;
  final String body;
  final String count;

  /// 0–1.
  final double progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = NumberFormat.percentPattern(context.localeName)
        .format(progress);
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
            const SizedBox(height: 8),
            DefaultTextStyle.merge(
              style: theme.textTheme.bodySmall,
              child: Row(
                children: [
                  Expanded(child: Text(count)),
                  Text(percent),
                ],
              ),
            ),
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
