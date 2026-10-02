import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../core/dates/wall_clock.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/day_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../data/models/transaction.dart';
import '../../assets_accounts/providers/assets_account_detail_providers.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../shell/widgets/page_load_error.dart';
import '../../transactions/widgets/transaction_list_row.dart';
import '../models/calendar_period.dart';
import '../providers/calendar_providers.dart';

/// The period's transactions, newest first, under a header per day when the
/// period has more than one. A tap opens the editor.
class CalendarTransactionsTab extends ConsumerWidget {
  const CalendarTransactionsTab({super.key, required this.period});

  final CalendarPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final transactions = ref.watch(calendarTransactionsProvider(period));
    final labels = ref.watch(calendarTransactionLabelsProvider(period));
    final categories = ref.watch(categoriesByIdProvider);
    final accounts = ref.watch(assetsAccountsProvider);
    final tomorrow = ref.watch(tomorrowProvider);

    return switch ((transactions, labels, categories, accounts)) {
      (AsyncError(), _, _, _) ||
      (_, AsyncError(), _, _) ||
      (_, _, AsyncError(), _) ||
      (_, _, _, AsyncError()) => PageLoadError(
        providers: [
          calendarTransactionsProvider(period),
          calendarTransactionLabelsProvider(period),
          categoriesByIdProvider,
          assetsAccountsProvider,
        ],
      ),
      (AsyncValue(value: []), _, _, _) => EmptyState(
        title: l10n.calendarNoTransactions,
      ),
      (
        AsyncValue(value: final transactions?),
        AsyncValue(value: final labels?),
        AsyncValue(value: final categories?),
        AsyncValue(value: final accounts?),
      ) =>
        _list(
          context,
          transactions,
          (Transaction t) => TransactionListRow(
            key: ValueKey(t.id),
            transaction: t,
            categories: categories,
            assetsAccounts: {for (final a in accounts) a.id: a},
            labels: labels[t.id] ?? const [],
            scheduled: !t.occurredAt.isBefore(tomorrow),
            onTap: () => context.push(Routes.transaction(t.id)),
          ),
        ),
      _ => PagePlaceholder(label: l10n.pageCalendar, rows: 3),
    };
  }

  Widget _list(
    BuildContext context,
    List<Transaction> transactions,
    Widget Function(Transaction) row,
  ) {
    final format = DateFormat.MMMMEEEEd(context.l10n.localeName);
    final divider = Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    final children = <Widget>[];
    DateTime? day;
    for (final t in transactions) {
      final date = startOfDay(t.occurredAt);
      if (!period.isSingleDay && date != day) {
        children.add(DayHeader(title: capitalizeFirst(format.format(date))));
      } else if (children.isNotEmpty) {
        children.add(divider);
      }
      day = date;
      children.add(row(t));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
