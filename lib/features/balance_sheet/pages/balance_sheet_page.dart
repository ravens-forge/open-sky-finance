import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/report_currency.dart';
import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../models/balance_sheet_baseline.dart';
import '../models/balance_sheet_comparison.dart';
import '../models/balance_sheet_side.dart';
import '../providers/balance_sheet_drill_down.dart';
import '../providers/balance_sheet_providers.dart';
import '../widgets/balance_sheet_account_row.dart';
import '../widgets/balance_sheet_compare_row.dart';
import '../widgets/balance_sheet_type_header.dart';
import '../widgets/net_worth_header.dart';
import '../../assets_accounts/widgets/assets_accounts_side_header.dart';
import '../../shell/widgets/page_load_error.dart';
import '../../shell/widgets/report_currency_row.dart';

class BalanceSheetPage extends HookConsumerWidget {
  const BalanceSheetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Shows what another page drilled down to, then clears it.
    final asOf = useState(
      useMemoized<DateTime>(
        () =>
            ref.read(balanceSheetDrillDownProvider) ?? ref.read(todayProvider),
      ),
    );
    void clearDrillDown() => Future.microtask(
      ref.read(balanceSheetDrillDownProvider.notifier).clear,
    );
    useEffect(() {
      if (ref.read(balanceSheetDrillDownProvider) != null) clearDrillDown();
      return null;
    }, const []);
    ref.listen(balanceSheetDrillDownProvider, (_, next) {
      if (next == null) return;
      asOf.value = next;
      clearDrillDown();
    });

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: asOf.value,
        firstDate: DateTime(1900),
        // A future date adds the scheduled transactions up to that day.
        lastDate: DateTime(2100),
        helpText: l10n.balanceSheetAsOf,
      );
      if (picked != null) asOf.value = picked;
    }

    final sides = ref.watch(balanceSheetSidesProvider(asOf.value));
    final main = ref.watch(reportCurrencyProvider).value;
    final hiddenCount = ref.watch(balanceSheetHiddenCountProvider).value ?? 0;
    final comparison =
        ref.watch(balanceSheetComparisonProvider).value ??
        BalanceSheetComparison.initial;
    final compareDate = comparison.dateFor(asOf.value);
    // A new date starts out loading: the last baseline stays meanwhile.
    final lastBaseline = useRef<BalanceSheetBaseline?>(null);
    final baseline = compareDate == null
        ? null
        : lastBaseline.value =
              ref.watch(balanceSheetBaselineProvider(compareDate)).value ??
              lastBaseline.value;

    return Column(
      children: [
        const ReportCurrencyRow(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.balanceSheetAsOf.toUpperCase(),
                  style: Theme.of(context).textTheme.eyebrow,
                ),
                TextButton.icon(
                  onPressed: pickDate,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.expand_more, size: 16),
                  label: Text(
                    DateFormat.yMMMd(l10n.localeName).format(asOf.value),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: SizedBox(
            width: double.infinity,
            child: BalanceSheetCompareRow(
              comparison: comparison,
              asOf: asOf.value,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch ((sides, main)) {
            (AsyncError(), _) => PageLoadError(
              providers: [balanceSheetSidesProvider(asOf.value)],
            ),
            (AsyncValue(value: []), _) => Center(
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
            (AsyncValue(value: final sides?), final String main) =>
              _BalanceSheetList(
                sides: sides,
                main: main,
                hiddenCount: hiddenCount,
                baseline: baseline,
              ),
            _ => PagePlaceholder(label: l10n.pageBalanceSheet),
          },
        ),
      ],
    );
  }
}

class _BalanceSheetList extends StatelessWidget {
  const _BalanceSheetList({
    required this.sides,
    required this.main,
    required this.hiddenCount,
    this.baseline,
  });

  final List<BalanceSheetSide> sides;
  final String main;
  final int hiddenCount;
  final BalanceSheetBaseline? baseline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final baseline = this.baseline;
    final beforeDate = baseline == null
        ? null
        : DateFormat.MMMd(l10n.localeName).format(baseline.date);
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
          assets: assets ?? 0,
          liabilities: liabilities ?? 0,
          currency: main,
          baseline: baseline,
        ),
        for (final side in sides) ...[
          AssetsAccountsSideHeader(
            key: ValueKey(side.isLiability),
            title: side.isLiability
                ? l10n.assetsAccountsLiabilities
                : l10n.assetsAccountsAssets,
            total: {main: side.total},
          ),
          for (final group in side.groups) ...[
            BalanceSheetTypeHeader(
              key: ValueKey(group.type),
              label: group.type.label(l10n),
              amount: group.total,
              currency: main,
            ),
            for (final item in group.accounts)
              BalanceSheetAccountRow(
                key: ValueKey(item.account.id),
                item: item,
                onTap: () =>
                    context.push(Routes.assetsAccount(item.account.id)),
                before: baseline?.balances[item.account.id] ?? 0,
                beforeDate: beforeDate,
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
