import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../core/dates/year_month.dart';
import '../../../data/models/label.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/transaction_filter.dart';
import '../../../data/providers.dart';
import '../models/transactions_month.dart';

part 'transactions_providers.g.dart';

/// The transactions of [month] matching [filter], newest first.
@riverpod
Stream<List<Transaction>> transactionsInMonth(
  Ref ref,
  YearMonth month,
  TransactionFilter filter,
) => ref
    .watch(transactionsRepositoryProvider)
    .watchInRange(month.start, month.end, filter: filter);

/// The labels of the month's transactions, by transaction id.
@riverpod
Stream<Map<String, List<Label>>> transactionLabels(Ref ref, YearMonth month) =>
    ref
        .watch(labelsRepositoryProvider)
        .watchByTransaction(month.start, month.end);

/// The list as the screen shows it: scheduled rows, day groups and the
/// period totals.
@riverpod
Future<TransactionsMonth> transactionsMonth(
  Ref ref,
  YearMonth month,
  TransactionFilter filter,
) async => TransactionsMonth.of(
  await ref.watch(transactionsInMonthProvider(month, filter).future),
  startOfTomorrow(),
);

/// Every label, by name, for the labels field and the filters.
@riverpod
Stream<List<Label>> labels(Ref ref) =>
    ref.watch(labelsRepositoryProvider).watchAll();

/// How many live transactions carry each label, over all time.
@riverpod
Stream<Map<String, int>> labelUses(Ref ref) => ref
    .watch(labelsRepositoryProvider)
    .watchTotals(DateTime(1), DateTime(9999))
    .map((totals) => {for (final t in totals) t.label.id: t.count});
