import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/main_currency.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/home_section_header.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../models/assets_account_with_balance.dart';
import '../models/assets_accounts_side.dart';
import '../providers/assets_accounts_controller.dart';
import '../providers/assets_accounts_providers.dart';
import '../widgets/assets_account_row.dart';
import '../widgets/assets_accounts_side_header.dart';

/// Assets and liabilities grouped by type with subtotals; favorite star, show
/// hidden, and reorder within a type by drag or move up/down.
class AssetsAccountsPage extends ConsumerStatefulWidget {
  const AssetsAccountsPage({super.key});

  @override
  ConsumerState<AssetsAccountsPage> createState() => _AssetsAccountsPageState();
}

class _AssetsAccountsPageState extends ConsumerState<AssetsAccountsPage> {
  var _showHidden = false;

  AssetsAccountsController get _controller =>
      ref.read(assetsAccountsControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = ref.watch(assetsAccountsWithBalanceProvider);
    final sides = ref.watch(assetsAccountsSidesProvider(_showHidden));
    final main = ref.watch(mainCurrencyProvider).value;

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
        (AsyncData(value: []), _, _) => Center(
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
          AsyncData(value: final all),
          AsyncData(value: final sides),
          final String main,
        ) =>
          _list(all, sides, main),
        (AsyncError(), _, _) || (_, AsyncError(), _) => Center(
          child: EmptyState(title: l10n.errorLoadFailed),
        ),
        _ => PagePlaceholder(label: l10n.pageAssetsAccounts),
      },
    );
  }

  Widget _list(
    List<AssetsAccountWithBalance> all,
    List<AssetsAccountsSide> sides,
    String main,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final allIds = [for (final a in all) a.account.id];
    void move(List<String> group, int from, int to) {
      if (from != to) _controller.move(allIds, group, from, to);
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
          mainCurrency: main,
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
              mainCurrency: main,
              onTap: () => context.push(Routes.assetsAccount(item.account.id)),
              onFavorite: (on) => _controller.setFavorite(item.account.id, on),
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
              value: _showHidden,
              onChanged: (on) => setState(() => _showHidden = on),
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
