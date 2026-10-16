import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/field_row.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../core/widgets/segmented_filter.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_group.dart';
import '../../../data/models/label.dart';
import '../../../data/models/transaction_filter.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../providers/transactions_providers.dart';

/// Type, assets account, category and label filters. Returns the new filter,
/// or `null` when dismissed without applying.
Future<TransactionFilter?> showTransactionsFilterSheet(
  BuildContext context,
  TransactionFilter filter,
) => showPickerSheet<TransactionFilter>(
  context,
  (context) => TransactionsFilterSheet(filter: filter),
);

class TransactionsFilterSheet extends HookConsumerWidget {
  const TransactionsFilterSheet({super.key, required this.filter});

  final TransactionFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = useState(filter);
    final current = state.value;

    // Picks one of [options] or "All" (the empty id, so a dismissed sheet
    // stays apart from clearing the filter).
    Future<void> pick(
      String title,
      String? selected,
      List<(String, String)> options,
      TransactionFilter Function(String? id) apply,
    ) async {
      final picked = await showChoiceSheet<String>(
        context,
        title: title,
        options: [('', l10n.filterAll), ...options],
        selected: selected ?? '',
      );
      if (picked == null) return;
      state.value = apply(picked.isEmpty ? null : picked);
    }

    final accounts =
        ref.watch(assetsAccountsProvider).value ?? const <AssetsAccount>[];
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final labels = ref.watch(labelsProvider).value ?? const <Label>[];
    final groups = {
      for (final g
          in ref.watch(categoryGroupsProvider).value ?? const <CategoryGroup>[])
        g.id: g.name,
    };

    final accountOptions = [for (final a in accounts) (a.id, a.name)];
    final categoryOptions = [
      for (final c in categories)
        (c.id, l10n.categoryInGroup(groups[c.groupId] ?? '', c.name)),
    ];
    final labelOptions = [for (final l in labels) (l.id, l.name)];
    String nameOf(List<(String, String)> options, String? id) =>
        options.where((o) => o.$1 == id).map((o) => o.$2).firstOrNull ??
        l10n.filterAll;

    return PickerSheet(
      title: l10n.transactionsFilterTitle,
      footer: [
        TextButton(
          onPressed: () => state.value = current.cleared(),
          child: Text(l10n.actionClear),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, current),
          child: Text(l10n.actionApply),
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SegmentedFilter<TransactionType?>(
            options: [
              (null, l10n.filterAll),
              for (final type in const [
                TransactionType.income,
                TransactionType.expense,
                TransactionType.transfer,
              ])
                (type, type.label(l10n)),
            ],
            selected: current.type,
            onChanged: (type) => state.value = current.withType(type),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldRow(
                label: l10n.fieldAssetsAccount,
                value: nameOf(accountOptions, current.assetsAccountId),
                onTap: () => pick(
                  l10n.fieldAssetsAccount,
                  current.assetsAccountId,
                  accountOptions,
                  current.withAssetsAccount,
                ),
              ),
              FieldRow(
                label: l10n.fieldCategory,
                value:
                    groups[current.categoryGroupId] ??
                    nameOf(categoryOptions, current.categoryId),
                onTap: current.type == TransactionType.transfer
                    ? null
                    : () => pick(
                        l10n.fieldCategory,
                        current.categoryId,
                        categoryOptions,
                        current.withCategory,
                      ),
              ),
              FieldRow(
                label: l10n.fieldLabel,
                value: nameOf(labelOptions, current.labelId),
                onTap: () => pick(
                  l10n.fieldLabel,
                  current.labelId,
                  labelOptions,
                  current.withLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
