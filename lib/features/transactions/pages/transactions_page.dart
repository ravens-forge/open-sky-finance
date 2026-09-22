import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/main_currency.dart';
import '../../../app/routes.dart';
import '../../../core/dates/wall_clock.dart';
import '../../../core/dates/year_month.dart';
import '../../../core/l10n.dart';
import '../../../core/money/currency_converter.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/day_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/month_switcher.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/label.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/transaction_filter.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../models/transactions_month.dart';
import '../providers/transactions_controller.dart';
import '../providers/transactions_drill_down.dart';
import '../providers/transactions_providers.dart';
import '../widgets/transaction_list_row.dart';
import '../widgets/transactions_empty_state.dart';
import '../widgets/transactions_filter_sheet.dart';
import '../widgets/transactions_search_bar.dart';
import '../widgets/transactions_summary_row.dart';

/// The ledger: period selector, summary, search and filters, the scheduled
/// rows and the month's transactions by day. Swiping a row moves it to the
/// Trash, with an Undo snack bar.
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  var _month = YearMonth.of(DateTime.now());
  var _filter = const TransactionFilter();
  final _search = TextEditingController();

  /// The last month loaded, with the month and filter it was loaded for.
  (TransactionsMonth, YearMonth, TransactionFilter)? _shown;

  @override
  void initState() {
    super.initState();
    // Shows what another page drilled down to, then clears it so it is not
    // shown again.
    ref.listenManual(transactionsDrillDownProvider, (_, next) {
      if (next == null) return;
      _search.clear();
      setState(() {
        _month = next.month;
        _filter = next.filter;
      });
      Future.microtask(ref.read(transactionsDrillDownProvider.notifier).clear);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month.start,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: context.l10n.transactionsPickMonth,
    );
    if (picked != null) setState(() => _month = YearMonth.of(picked));
  }

  Future<void> _openFilters() async {
    final picked = await showTransactionsFilterSheet(context, _filter);
    if (picked != null) setState(() => _filter = picked);
  }

  void _trash(Transaction transaction) {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(transactionsControllerProvider.notifier);
    controller.trash(transaction.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.transactionsMovedToTrash),
        action: SnackBarAction(
          label: l10n.actionUndo,
          onPressed: () => controller.restore(transaction.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final month = ref.watch(transactionsMonthProvider(_month, _filter));
    final converter = ref.watch(currencyConverterProvider).value;
    if (month case AsyncData(:final value)) _shown = (value, _month, _filter);
    // Each keystroke is a new filter, so a new provider that starts out
    // loading. The previous result stays meanwhile, and with it the search
    // field inside the list, so the keyboard stays open. A reload of the same
    // one (a swipe to the Trash) still waits, or the dismissed row would be
    // drawn again.
    final shown = switch ((month, _shown)) {
      (AsyncData(:final value), _) => value,
      (AsyncLoading(), (final value, final m, final f))
          when (m, f) != (_month, _filter) =>
        value,
      _ => null,
    };

    return Column(
      children: [
        MonthSwitcher(
          month: _month,
          onChanged: (month) => setState(() => _month = month),
          onPick: _pickMonth,
        ),
        const Divider(),
        Expanded(
          child: switch ((month, shown, converter)) {
            (AsyncError(), _, _) => Center(
              child: EmptyState(title: l10n.errorLoadFailed),
            ),
            (_, final shown?, final CurrencyConverter converter) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              children: _sections(shown, converter),
            ),
            _ => PagePlaceholder(label: l10n.pageTransactions),
          },
        ),
      ],
    );
  }

  List<Widget> _sections(TransactionsMonth month, CurrencyConverter converter) {
    final l10n = context.l10n;
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
        ref.watch(transactionLabelsProvider(_month)).value ??
        const <String, List<Label>>{};
    final tomorrow = startOfTomorrow();
    final day = DateFormat.MMMMEEEEd(l10n.localeName);

    Widget total(Map<String, int> net) {
      final converted = converter.convert(net);
      return AmountText(
        converted.amount,
        currency: converter.mainCurrency,
        approximate: converted.approximate,
      );
    }

    final rule = BorderSide(
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    // Rows of a group are ruled apart; the heading already rules the first.
    Widget row(Transaction t, {required bool first}) => Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: const TransactionSwipeBackground(),
      onDismissed: (_) => _trash(t),
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
          onTap: () => context.push(Routes.transaction(t.id)),
        ),
      ),
    );
    final filtered = _filter.count > 0 || _filter.query.trim().isNotEmpty;

    return [
      TransactionsSummaryRow(totals: month.totals, converter: converter),
      // An empty period offers its next steps instead of a search.
      if (!month.isEmpty || filtered)
        TransactionsSearchBar(
          controller: _search,
          onChanged: (text) =>
              setState(() => _filter = _filter.withQuery(text)),
          filterCount: _filter.count,
          onFilters: _openFilters,
        ),
      if (month.isEmpty)
        TransactionsEmptyState(
          month: _month,
          filtered: filtered,
          onClear: () {
            _search.clear();
            setState(() => _filter = const TransactionFilter());
          },
          onPreviousMonth: () => setState(() => _month = _month.plus(-1)),
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
    ];
  }
}
