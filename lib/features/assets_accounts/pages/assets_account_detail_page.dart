import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/dates/year_month.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/not_found_page.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../models/credit_usage.dart';
import '../providers/assets_account_detail_providers.dart';
import '../providers/assets_accounts_controller.dart';
import '../providers/assets_accounts_providers.dart';
import '../widgets/assets_account_balance_header.dart';
import '../widgets/assets_account_month_view.dart';
import '../widgets/balance_chart.dart';
import '../widgets/credit_usage_section.dart';

/// Balance, credit usage, balance chart and the transactions of a month.
class AssetsAccountDetailPage extends ConsumerStatefulWidget {
  const AssetsAccountDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AssetsAccountDetailPage> createState() =>
      _AssetsAccountDetailPageState();
}

class _AssetsAccountDetailPageState
    extends ConsumerState<AssetsAccountDetailPage> {
  var _month = YearMonth.of(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final account = ref.watch(assetsAccountProvider(widget.id));
    final balance = ref.watch(assetsAccountBalancesProvider).value?[widget.id];
    final history = ref
        .watch(assetsAccountBalanceHistoryProvider(widget.id))
        .value;

    final a = account.value;
    if (account is AsyncData && a == null) {
      // Deleted while open.
      return NotFoundPage(onHome: () => context.go(Routes.home));
    }
    if (a == null || balance == null) {
      return Scaffold(
        appBar: AppBar(),
        body: PagePlaceholder(label: l10n.pageAssetsAccounts),
      );
    }
    final usage = CreditUsage.of(a, balance);

    return Scaffold(
      appBar: AppBar(
        title: Text(a.name),
        actions: [
          IconButton(
            isSelected: a.isFavorite,
            tooltip: l10n.assetsAccountFavorite(a.name),
            icon: const Icon(Icons.star_border),
            selectedIcon: Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () => ref
                .read(assetsAccountsControllerProvider.notifier)
                .setFavorite(a.id, !a.isFavorite),
          ),
          IconButton(
            tooltip: l10n.actionEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.editAssetsAccount(a.id)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          AssetsAccountBalanceHeader(account: a, balance: balance),
          if (usage != null) ...[
            const SizedBox(height: 20),
            CreditUsageSection(usage: usage, currency: a.currency),
          ],
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.assetsAccountBalanceOverTime,
                    style: text.titleMedium,
                  ),
                ),
              ),
              Text(
                l10n.assetsAccountLastMonths(balanceChartMonths),
                style: text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (history != null)
            BalanceChart(history: history, currency: a.currency),
          const SizedBox(height: 20),
          AssetsAccountMonthView(
            account: a,
            month: _month,
            onMonthChanged: (m) => setState(() => _month = m),
          ),
        ],
      ),
    );
  }
}
