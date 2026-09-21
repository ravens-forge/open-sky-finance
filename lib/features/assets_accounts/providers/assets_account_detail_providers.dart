import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../core/dates/year_month.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/transaction_filter.dart';
import '../../../data/providers.dart';
import '../models/assets_account_month.dart';

part 'assets_account_detail_providers.g.dart';

/// Months shown by the balance chart, the current one last.
const balanceChartMonths = 6;

/// `null` once deleted.
@riverpod
Stream<AssetsAccount?> assetsAccount(Ref ref, String id) =>
    ref.watch(assetsAccountsRepositoryProvider).watchById(id);

/// Month-end balances of the last [balanceChartMonths] months; the current
/// month ends today.
@riverpod
Stream<Map<YearMonth, int>> assetsAccountBalanceHistory(Ref ref, String id) {
  final now = YearMonth.of(DateTime.now());
  return ref
      .watch(balancesRepositoryProvider)
      .watchBalanceHistory(
        id,
        now.plus(1 - balanceChartMonths),
        now,
        before: startOfTomorrow(),
      );
}

@riverpod
Stream<List<Transaction>> assetsAccountTransactions(
  Ref ref,
  String id,
  YearMonth month,
) => ref
    .watch(transactionsRepositoryProvider)
    .watchInRange(
      month.start,
      month.end,
      filter: TransactionFilter(assetsAccountId: id),
    );

@riverpod
Stream<Map<String, int>> balancesBefore(Ref ref, DateTime before) =>
    ref.watch(balancesRepositoryProvider).watchBalances(before);

/// Transactions of [month] touching the assets account, by day, with the
/// balance at the end of each day (scheduled ones included).
@riverpod
Future<AssetsAccountMonth> assetsAccountMonth(
  Ref ref,
  String id,
  YearMonth month,
) async {
  final transactions = await ref.watch(
    assetsAccountTransactionsProvider(id, month).future,
  );
  final balances = await ref.watch(balancesBeforeProvider(month.end).future);
  return AssetsAccountMonth.of(id, transactions, balances[id] ?? 0);
}

/// Every category by id, for transaction rows.
@riverpod
Future<Map<String, Category>> categoriesById(Ref ref) async => {
  for (final c
      in await ref.watch(categoriesRepositoryProvider).watchCategories().first)
    c.id: c,
};
