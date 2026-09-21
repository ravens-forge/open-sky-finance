import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/year_month.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/empty_state.dart';

/// Nothing to list: a first-transaction nudge, or the hint that the search
/// and filters hide everything.
class TransactionsEmptyState extends StatelessWidget {
  const TransactionsEmptyState({
    super.key,
    required this.month,
    required this.filtered,
    required this.onClear,
    required this.onPreviousMonth,
    required this.onAdd,
    required this.onImport,
  });

  final YearMonth month;

  /// A search or filter is on, so the period may well have transactions.
  final bool filtered;
  final VoidCallback onClear;
  final VoidCallback onPreviousMonth;
  final VoidCallback onAdd;

  /// Import from Bluecoins (Backups).
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Inside a sentence: the locale's own case (`August`, `agosto`, `août`).
    String name(YearMonth month) =>
        DateFormat.MMMM(l10n.localeName).format(month.start);
    return EmptyState(
      title: filtered
          ? l10n.transactionsNoResults
          : l10n.transactionsEmpty(name(month)),
      message: filtered ? null : l10n.transactionsEmptyMessage,
      actions: filtered
          ? [OutlinedButton(onPressed: onClear, child: Text(l10n.actionClear))]
          : [
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(l10n.transactionsAdd),
              ),
              OutlinedButton(
                onPressed: onPreviousMonth,
                child: Text(l10n.transactionsGoToMonth(name(month.plus(-1)))),
              ),
              TextButton(
                onPressed: onImport,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: Text(l10n.transactionsImportBluecoins),
              ),
            ],
    );
  }
}

/// Shown behind a row being swiped to the Trash.
class TransactionSwipeBackground extends StatelessWidget {
  const TransactionSwipeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: scheme.errorContainer,
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
    );
  }
}
