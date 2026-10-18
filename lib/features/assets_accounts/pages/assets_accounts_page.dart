import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../app/default_currency.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/money/format_money.dart';
import '../../../core/reorder_ids.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/home_section_header.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../data/providers.dart';
import '../../shell/widgets/page_load_error.dart';
import '../models/assets_account_with_balance.dart';
import '../models/assets_accounts_side.dart';
import '../providers/assets_accounts_providers.dart';
import '../widgets/assets_account_row.dart';
import '../widgets/assets_accounts_side_header.dart';

/// Assets and liabilities grouped by type with subtotals; favorite star, show
/// hidden, and reorder within a type by drag or move up/down.
class AssetsAccountsPage extends HookConsumerWidget {
  const AssetsAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final showHidden = useState(false);
    final all = ref.watch(assetsAccountsWithBalanceProvider);
    final sides = ref.watch(assetsAccountsSidesProvider(showHidden.value));
    final main = ref.watch(defaultCurrencyProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pageAssetsAccounts),
        actions: [
          IconButton(
            tooltip: l10n.editorNewAssetsAccount,
            icon: const Icon(Icons.add),
            onPressed: () => context.push(Routes.newAssetsAccount),
          ),
        ],
      ),
      body: switch ((all, sides, main)) {
        (AsyncValue(value: []), _, _) => Center(
          child: SingleChildScrollView(
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
        ),
        (
          AsyncValue(value: final all?),
          AsyncValue(value: final sides?),
          final String main,
        ) =>
          _AssetsAccountList(
            all: all,
            sides: sides,
            main: main,
            showHidden: showHidden,
          ),
        (AsyncError(), _, _) || (_, AsyncError(), _) => PageLoadError(
          providers: [
            assetsAccountsWithBalanceProvider,
            assetsAccountsSidesProvider,
          ],
        ),
        _ => PagePlaceholder(label: l10n.pageAssetsAccounts),
      },
    );
  }
}

class _AssetsAccountList extends ConsumerWidget {
  const _AssetsAccountList({
    required this.all,
    required this.sides,
    required this.main,
    required this.showHidden,
  });

  final List<AssetsAccountWithBalance> all;
  final List<AssetsAccountsSide> sides;
  final String main;
  final ValueNotifier<bool> showHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final repository = ref.read(assetsAccountsRepositoryProvider);
    final allIds = [for (final a in all) a.account.id];
    final shared = sharedSymbols([
      for (final a in all) a.account.currency,
    ], l10n.localeName);
    void move(List<String> group, int from, int to) {
      if (from != to) {
        repository.reorder(reorderIds(allIds, group, from, to));
      }
    }

    // Headers and rows share one list; rows only move within their type
    // group, whose ids and first index are kept here.
    final children = <Widget>[];
    final groupOf = <int?>[];
    final groups = <List<String>>[];
    final starts = <int>[];
    for (final side in sides) {
      children.add(
        AssetsAccountsSideHeader(
          key: ValueKey(side.isLiability),
          title: side.isLiability
              ? l10n.assetsAccountsLiabilities
              : l10n.assetsAccountsAssets,
          total: side.total,
        ),
      );
      groupOf.add(null);
      for (final group in side.groups) {
        children.add(
          Padding(
            key: ValueKey(group.type),
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              group.type.label(l10n).toUpperCase(),
              style: theme.textTheme.eyebrow,
            ),
          ),
        );
        groupOf.add(null);
        final ids = [for (final a in group.accounts) a.account.id];
        groups.add(ids);
        starts.add(children.length);
        for (final (i, item) in group.accounts.indexed) {
          children.add(
            AssetsAccountRow(
              key: ValueKey(item.account.id),
              item: item,
              index: children.length,
              defaultCurrency: main,
              code: shared.contains(item.account.currency),
              onTap: () => context.push(Routes.assetsAccount(item.account.id)),
              onFavorite: (on) => repository.setFavorite(item.account.id, on),
              onMoveUp: i > 0 ? () => move(ids, i, i - 1) : null,
              onMoveDown: i < ids.length - 1 ? () => move(ids, i, i + 1) : null,
            ),
          );
          groupOf.add(groups.length - 1);
        }
      }
    }

    final hiddenCount = all.where((a) => a.account.isHidden).length;
    return ReorderableListView(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      proxyDecorator: homeSectionProxyDecorator,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hiddenCount > 0)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.assetsAccountsShowHidden(hiddenCount)),
              value: showHidden.value,
              onChanged: (on) => showHidden.value = on,
            ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Icon(Icons.star, size: 16, color: theme.colorScheme.secondary),
                Expanded(
                  child: Text(
                    l10n.assetsAccountsIntro,
                    style: theme.textTheme.bodySmall!.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      onReorderItem: (from, to) {
        final g = groupOf[from];
        if (g == null || groupOf[to] != g) return;
        move(groups[g], from - starts[g], to - starts[g]);
      },
      children: children,
    );
  }
}
