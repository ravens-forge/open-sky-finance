import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../core/dates/wall_clock.dart';
import '../../../core/dates/year_month.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/currency_totals.dart';
import '../../../core/widgets/day_header.dart';
import '../../../core/widgets/month_switcher.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/label.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/transaction_filter.dart';
import '../../../data/providers.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../../shell/widgets/page_load_error.dart';
import '../models/transactions_month.dart';
import '../providers/transactions_drill_down.dart';
import '../providers/transactions_providers.dart';
import '../widgets/transaction_list_row.dart';
import '../widgets/transaction_options_sheet.dart';
import '../widgets/transactions_empty_state.dart';
import '../widgets/transactions_filter_sheet.dart';
import '../widgets/transactions_search_bar.dart';
import '../widgets/transactions_summary_row.dart';

class TransactionsPage extends HookConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Opens on what another page drilled down to, if anything.
    final drilled = useMemoized(() => ref.read(transactionsDrillDownProvider));
    final selected = useState(
      useMemoized<YearMonth>(
        () => drilled?.month ?? ref.read(currentMonthProvider),
      ),
    );
    final filter = useState(drilled?.filter ?? const TransactionFilter());
    final search = useTextEditingController();
    // The last month loaded.
    final last = useRef<TransactionsMonth?>(null);

    // Clears the drill-down once shown, so it is not shown again.
    void clearDrillDown() => Future.microtask(
      ref.read(transactionsDrillDownProvider.notifier).clear,
    );
    useEffect(() {
      if (drilled != null) clearDrillDown();
      return null;
    }, const []);
    ref.listen(transactionsDrillDownProvider, (_, next) {
      if (next == null) return;
      search.clear();
      selected.value = next.month;
      filter.value = next.filter;
      clearDrillDown();
    });

    Future<void> pickMonth() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selected.value.start,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        initialDatePickerMode: DatePickerMode.year,
        helpText: l10n.transactionsPickMonth,
      );
      if (picked != null) selected.value = YearMonth.of(picked);
    }

    final month = ref.watch(
      transactionsMonthProvider(selected.value, filter.value),
    );
    // Each keystroke is a new filter, so a new provider that starts out
    // loading. The previous result stays meanwhile, and with it the search
    // field inside the list, so the keyboard stays open.
    final shown = last.value = month.value ?? last.value;

    return Column(
      children: [
        MonthSwitcher(
          month: selected.value,
          onChanged: (value) => selected.value = value,
          onPick: pickMonth,
        ),
        const Divider(),
        Expanded(
          child: switch ((month, shown)) {
            (AsyncError(), _) => PageLoadError(
              providers: [
                transactionsMonthProvider(selected.value, filter.value),
              ],
            ),
            (_, final shown?) => _TransactionList(
              month: shown,
              selected: selected,
              filter: filter,
              search: search,
            ),
            _ => PagePlaceholder(label: l10n.pageTransactions),
          },
        ),
      ],
    );
  }
}

/// The totals, the search and the transactions of [month] by day.
class _TransactionList extends ConsumerWidget {
  const _TransactionList({
    required this.month,
    required this.selected,
    required this.filter,
    required this.search,
  });

  final TransactionsMonth month;
  final ValueNotifier<YearMonth> selected;
  final ValueNotifier<TransactionFilter> filter;
  final TextEditingController search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    Future<void> openFilters() async {
      final picked = await showTransactionsFilterSheet(context, filter.value);
      if (picked != null) filter.value = picked;
    }

    void trash(Transaction transaction) {
      final messenger = ScaffoldMessenger.of(context);
      final repository = ref.read(transactionsRepositoryProvider);
      repository.trash(transaction.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.transactionsMovedToTrash),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () => repository.restore(transaction.id),
          ),
        ),
      );
    }

    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final accounts = {
      for (final a
          in ref.watch(assetsAccountsProvider).value ?? const <AssetsAccount>[])
        a.id: a,
    };
    final labels =
        ref.watch(transactionLabelsProvider(selected.value)).value ??
        const <String, List<Label>>{};
    final tomorrow = ref.watch(tomorrowProvider);
    final day = DateFormat.MMMMEEEEd(l10n.localeName);

    // One line per currency, never converted.
    Widget total(Map<String, int> net) =>
        CurrencyTotals(net, amountStyle: AmountStyle.signed);

    final rule = BorderSide(
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    // Rows of a group are ruled apart; the heading already rules the first.
    void edit(Transaction t) => context.push(Routes.transaction(t.id));
    Widget row(Transaction t, {required bool first}) => Semantics(
      key: ValueKey(t.id),
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.actionEdit): () => edit(t),
        CustomSemanticsAction(label: l10n.actionDelete): () => trash(t),
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: first ? BorderSide.none : rule),
        ),
        child: TransactionListRow(
          transaction: t,
          categories: categories,
          assetsAccounts: accounts,
          labels: labels[t.id] ?? const [],
          scheduled: !t.occurredAt.isBefore(tomorrow),
          onTap: () => edit(t),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            showTransactionOptionsSheet(
              context,
              t,
              onEdit: () => edit(t),
              onDelete: () => trash(t),
            );
          },
        ),
      ),
    );
    final current = filter.value;
    final filtered = current.count > 0 || current.query.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
      children: [
        TransactionsSummaryRow(totals: month.totals),
        // An empty period offers its next steps instead of a search.
        if (!month.isEmpty || filtered)
          TransactionsSearchBar(
            controller: search,
            onChanged: (text) => filter.value = current.withQuery(text),
            filterCount: current.count,
            onFilters: openFilters,
          ),
        if (month.isEmpty)
          TransactionsEmptyState(
            month: selected.value,
            filtered: filtered,
            onClear: () {
              search.clear();
              filter.value = const TransactionFilter();
            },
            onPreviousMonth: () => selected.value = selected.value.plus(-1),
            onAdd: () => context.push(Routes.newTransaction()),
            onImport: () => context.push(Routes.backups),
          ),
        if (month.scheduled.isNotEmpty) ...[
          DayHeader(
            title: l10n.chipScheduled,
            trailing: total(month.scheduledNet),
          ),
          for (final (i, t) in month.scheduled.indexed) row(t, first: i == 0),
        ],
        for (final d in month.days) ...[
          DayHeader(
            title: capitalizeFirst(day.format(d.date)),
            trailing: total(d.net),
          ),
          for (final (i, t) in d.transactions.indexed) row(t, first: i == 0),
        ],
      ],
    );
  }
}
