import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/now.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_note.dart';
import '../providers/budgets_providers.dart';

class BudgetsEmptyState extends ConsumerWidget {
  const BudgetsEmptyState({super.key, required this.onSet});

  final VoidCallback onSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final overview = ref
        .watch(budgetOverviewProvider(ref.watch(currentMonthProvider)))
        .value;
    final spent = overview?.notBudgeted;
    return SingleChildScrollView(
      child: Column(
        children: [
          EmptyState(
            title: l10n.budgetEmptyTitle,
            message: l10n.budgetEmptyMessage,
            actions: [
              FilledButton.icon(
                onPressed: onSet,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.budgetSet),
              ),
            ],
          ),
          if (overview != null && spent != null && spent.amount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: InfoNote(
                l10n.budgetEmptyUnbudgeted(() {
                  final amount = formatMoney(
                    spent.amount,
                    currency: overview.currency,
                    locale: l10n.localeName,
                  );
                  return spent.approximate
                      ? l10n.amountApproximate(amount)
                      : amount;
                }()),
              ),
            ),
        ],
      ),
    );
  }
}
