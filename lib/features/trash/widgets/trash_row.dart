import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../transactions/widgets/transaction_list_row.dart';

class TrashRow extends StatelessWidget {
  const TrashRow({
    super.key,
    required this.transaction,
    required this.categories,
    required this.assetsAccounts,
    required this.onRestore,
    required this.onDelete,
  });

  final Transaction transaction;
  final Map<String, Category> categories;
  final Map<String, AssetsAccount> assetsAccounts;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finance = FinanceColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: 0.8,
            child: TransactionListRow(
              transaction: transaction,
              categories: categories,
              assetsAccounts: assetsAccounts,
              labels: const [],
              scheduled: false,
              trashed: true,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 52),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore, size: 16),
                  label: Text(l10n.actionRestore),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.trashDeletePermanently,
                  onPressed: onDelete,
                  color: finance.expense,
                  style: IconButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
