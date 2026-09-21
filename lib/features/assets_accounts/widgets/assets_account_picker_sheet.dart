import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../models/assets_account_with_balance.dart';
import '../providers/assets_accounts_providers.dart';
import 'assets_account_avatar.dart';

/// Picks an assets account: assets then liabilities, each row with its type
/// icon, type and currency, and balance. Hidden accounts are left out, as is
/// [excludeId] (the other side of a transfer). Returns the chosen id, `null`
/// when dismissed.
Future<String?> showAssetsAccountPickerSheet(
  BuildContext context, {
  String? selectedId,
  String? excludeId,
}) => showPickerSheet<String>(
  context,
  (context) =>
      AssetsAccountPickerSheet(selectedId: selectedId, excludeId: excludeId),
);

class AssetsAccountPickerSheet extends ConsumerWidget {
  const AssetsAccountPickerSheet({super.key, this.selectedId, this.excludeId});

  final String? selectedId;
  final String? excludeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accounts =
        ref.watch(assetsAccountsWithBalanceProvider).value ??
        const <AssetsAccountWithBalance>[];
    final rule = BorderSide(color: scheme.outlineVariant);

    final rows = <Widget>[];
    for (final isLiability in const [false, true]) {
      final side = [
        for (final a in accounts)
          if (!a.account.isHidden &&
              a.account.id != excludeId &&
              a.account.type.isLiability == isLiability)
            a,
      ];
      if (side.isEmpty) continue;
      rows.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.only(top: rows.isEmpty ? 10 : 16, bottom: 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outline)),
          ),
          child: Text(
            (isLiability
                    ? l10n.assetsAccountsLiabilities
                    : l10n.assetsAccountsAssets)
                .toUpperCase(),
            style: theme.textTheme.eyebrow,
          ),
        ),
      );
      for (final (i, AssetsAccountWithBalance(:account, :balance))
          in side.indexed) {
        final selected = account.id == selectedId;
        rows.add(
          Semantics(
            selected: selected,
            child: InkWell(
              onTap: () => Navigator.pop(context, account.id),
              child: Container(
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: selected ? scheme.primaryContainer : null,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(top: i == 0 ? BorderSide.none : rule),
                  ),
                  constraints: const BoxConstraints(minHeight: 58),
                  child: Row(
                    spacing: 12,
                    children: [
                      AssetsAccountAvatar(account.type),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.name, style: theme.textTheme.rowTitle),
                            Text(
                              l10n.assetsAccountPickerSubtitle(
                                account.type.label(l10n),
                                account.currency,
                              ),
                              style: theme.textTheme.rowSubtitle,
                            ),
                          ],
                        ),
                      ),
                      AmountText(
                        balance,
                        currency: account.currency,
                        amountStyle: AmountStyle.balance,
                        style: theme.textTheme.rowAmount,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return PickerSheet(
      title: l10n.fieldAssetsAccount,
      footer: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // The editor stays below and picks the new account up.
              final router = GoRouter.of(context);
              Navigator.pop(context);
              router.push(Routes.newAssetsAccount);
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.editorNewAssetsAccount),
          ),
        ),
      ],
      children: [
        ...rows,
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          decoration: BoxDecoration(border: Border(top: rule)),
          child: Text(
            l10n.assetsAccountPickerHiddenNote,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
