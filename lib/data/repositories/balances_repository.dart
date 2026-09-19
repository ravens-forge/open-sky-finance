import 'package:drift/drift.dart';

import '../../core/dates/year_month.dart';
import '../database/app_database.dart';
import '../database/tables/assets_accounts_table.dart';
import '../database/tables/transactions_table.dart';
import 'report_sql.dart';

part 'balances_repository.g.dart';

@DriftAccessor(tables: [AssetsAccountsTable, TransactionsTable])
class BalancesRepository extends DatabaseAccessor<AppDatabase>
    with _$BalancesRepositoryMixin {
  BalancesRepository(super.attachedDatabase);

  /// Balance of every assets account (in its own currency) before [before],
  /// hidden ones included.
  Stream<Map<String, int>> watchBalances(DateTime before) =>
      customSelect(
        '''
WITH $movesCte
SELECT a.id AS id, COALESCE(SUM(m.amount), 0) AS balance
FROM assets_accounts a
LEFT JOIN moves m ON m.assets_account_id = a.id AND m.occurred_at < ?1
GROUP BY a.id''',
        variables: [wallClockVariable(before)],
        readsFrom: {assetsAccountsTable, transactionsTable},
      ).watch().map(
        (rows) => {
          for (final r in rows) r.read<String>('id'): r.read<int>('balance'),
        },
      );

  /// Balance of one assets account at the end of each month in [from, to],
  /// never counting transactions on or after [before].
  Stream<Map<YearMonth, int>> watchBalanceHistory(
    String assetsAccountId,
    YearMonth from,
    YearMonth to, {
    required DateTime before,
  }) {
    final end = to.end.isBefore(before) ? to.end : before;
    return customSelect(
      '''
WITH $movesCte
SELECT CASE WHEN occurred_at < ?2 THEN '' ELSE substr(occurred_at, 1, 7)
  END AS month, SUM(amount) AS total
FROM moves WHERE assets_account_id = ?1 AND occurred_at < ?3
GROUP BY 1''',
      variables: [
        Variable(assetsAccountId),
        wallClockVariable(from.start),
        wallClockVariable(end),
      ],
      readsFrom: {assetsAccountsTable, transactionsTable},
    ).watch().map((rows) {
      final deltas = {
        for (final r in rows) r.read<String>('month'): r.read<int>('total'),
      };
      var running = deltas[''] ?? 0;
      final history = <YearMonth, int>{};
      for (var m = from; m.compareTo(to) <= 0; m = m.plus(1)) {
        running += deltas['$m'] ?? 0;
        history[m] = running;
      }
      return history;
    });
  }

  /// Net worth of the chart accounts (excluding those excluded from net worth)
  /// at the end of each month in [from, to], never counting transactions on or
  /// after [before] (pass the start of tomorrow to leave scheduled ones out).
  Stream<Map<YearMonth, Map<String, int>>> watchNetWorthHistory(
    YearMonth from,
    YearMonth to, {
    required DateTime before,
  }) {
    final end = to.end.isBefore(before) ? to.end : before;
    return customSelect(
      '''
WITH $chartAccountsCte, $movesCte
SELECT CASE WHEN m.occurred_at < ?1 THEN '' ELSE substr(m.occurred_at, 1, 7)
  END AS month, m.currency AS currency, SUM(m.amount) AS total
FROM moves m JOIN chart_accounts c ON c.id = m.assets_account_id
WHERE c.exclude_from_net_worth = 0 AND m.occurred_at < ?2
GROUP BY 1, 2''',
      variables: [wallClockVariable(from.start), wallClockVariable(end)],
      readsFrom: {assetsAccountsTable, transactionsTable},
    ).watch().map((rows) {
      final deltas = <String, Map<String, int>>{};
      for (final r in rows) {
        (deltas[r.read<String>('month')] ??= {})[r.read<String>('currency')] = r
            .read<int>('total');
      }
      final running = <String, int>{...?deltas['']};
      final history = <YearMonth, Map<String, int>>{};
      for (var m = from; m.compareTo(to) <= 0; m = m.plus(1)) {
        deltas['$m']?.forEach((c, v) => running[c] = (running[c] ?? 0) + v);
        history[m] = {...running};
      }
      return history;
    });
  }
}
