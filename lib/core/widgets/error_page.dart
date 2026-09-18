import 'package:flutter/material.dart';

import '../finance_colors.dart';
import '../l10n.dart';
import 'info_note.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    required this.onReport,
    this.note,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onReport;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: finance.expenseContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, color: finance.expense),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.headlineLarge),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyLarge!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: onRetry,
                child: Text(l10n.actionTryAgain),
              ),
              OutlinedButton(
                onPressed: onReport,
                child: Text(l10n.actionReportBug),
              ),
            ],
          ),
          if (note != null) ...[const SizedBox(height: 24), InfoNote(note!)],
        ],
      ),
    );
  }
}
