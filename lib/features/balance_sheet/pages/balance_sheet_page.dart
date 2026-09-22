import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/main_currency.dart';
import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../models/balance_sheet_side.dart';
import '../providers/balance_sheet_providers.dart';
import '../widgets/balance_sheet_account_row.dart';
import '../widgets/balance_sheet_type_header.dart';
import '../widgets/net_worth_header.dart';
import '../../assets_accounts/widgets/assets_accounts_side_header.dart';

class BalanceSheetPage extends ConsumerStatefulWidget {
  const BalanceSheetPage({super.key});

  @override
  ConsumerState<BalanceSheetPage> createState() => _BalanceSheetPageState();
}

class _BalanceSheetPageState extends ConsumerState<BalanceSheetPage> {
  late var _asOf = ref.read(todayProvider);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOf,
      firstDate: DateTime(1900),
      lastDate: ref.read(todayProvider),
      helpText: context.l10n.balanceSheetAsOf,
    );
    if (picked != null) setState(() => _asOf = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sides = ref.watch(balanceSheetSidesProvider(_asOf));
    final main = ref.watch(mainCurrencyProvider).value;
    final hiddenCount = ref.watch(balanceSheetHiddenCountProvider).value ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.balanceSheetAsOf.toUpperCase(),
                style: Theme.of(context).textTheme.eyebrow,
              ),
              TextButton.icon(
                onPressed: _pickDate,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.expand_more, size: 16),
                label: Text(
                  DateFormat.yMMMd(l10n.localeName).format(_asOf),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch ((sides, main)) {
            (AsyncError(), _) => Center(
              child: EmptyState(title: l10n.errorLoadFailed),
            ),
            (AsyncData(value: []), _) => Center(
              child: EmptyState(
                title: l10n.assetsAccountsEmpty,
                actions: [
                  FilledButton(
                    onPressed: () => context.push(Routes.newAssetsAccount),
                    child: Text(l10n.editorNewAssetsAccount),
                  ),
                ],
              ),
            ),
            (AsyncData(value: final sides), final String main) => _list(
              sides,
              main,
              hiddenCount,
            ),
            _ => PagePlaceholder(label: l10n.pageBalanceSheet),
          },
        ),
      ],
    );
  }

  Widget _list(List<BalanceSheetSide> sides, String main, int hiddenCount) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final assets = sides
        .where((s) => !s.isLiability)
        .map((s) => s.total)
        .firstOrNull;
    final liabilities = sides
        .where((s) => s.isLiability)
        .map((s) => s.total)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        NetWorthHeader(
          assets: assets?.amount ?? 0,
          liabilities: liabilities?.amount ?? 0,
          currency: main,
        ),
        for (final side in sides) ...[
          AssetsAccountsSideHeader(
            key: ValueKey(side.isLiability),
            title: side.isLiability
                ? l10n.assetsAccountsLiabilities
                : l10n.assetsAccountsAssets,
            total: side.total,
            mainCurrency: main,
          ),
          for (final group in side.groups) ...[
            BalanceSheetTypeHeader(
              key: ValueKey(group.type),
              label: group.type.label(l10n),
              amount: group.total.amount,
              mainCurrency: main,
              approximate: group.total.approximate,
            ),
            for (final item in group.accounts)
              BalanceSheetAccountRow(
                key: ValueKey(item.account.id),
                item: item,
                onTap: () =>
                    context.push(Routes.assetsAccount(item.account.id)),
              ),
          ],
        ],
        if (hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.visibility_off_outlined, size: 16, color: muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    children: [
                      Text(
                        l10n.balanceSheetHiddenNote(hiddenCount),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => context.push(Routes.assetsAccounts),
                        child: Text(
                          l10n.balanceSheetViewAssetsAccounts,
                          style: theme.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
