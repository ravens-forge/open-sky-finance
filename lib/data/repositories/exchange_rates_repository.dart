import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../core/money/currency_converter.dart';
import '../database/app_database.dart';
import '../database/tables/assets_accounts_table.dart';
import '../database/tables/transactions_table.dart';
import 'report_sql.dart';

part 'exchange_rates_repository.g.dart';

@DriftAccessor(tables: [AssetsAccountsTable, TransactionsTable])
class ExchangeRatesRepository extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRatesRepositoryMixin {
  ExchangeRatesRepository(super.attachedDatabase);

  /// Units of [mainCurrency] per unit of each other currency, from the latest
  /// transfer before [before] between that currency and [mainCurrency] (either
  /// direction). Currencies without such a transfer are missing.
  Stream<Map<String, Decimal>> watchRates(
    String mainCurrency,
    DateTime before,
  ) =>
      customSelect(
        '''
SELECT CASE WHEN t.currency = ?1 THEN a.currency ELSE t.currency END AS other,
  t.currency AS source, t.amount AS amount, t.to_amount AS to_amount,
  MAX(t.occurred_at) AS last_at
FROM transactions t JOIN assets_accounts a ON a.id = t.to_assets_account_id
WHERE t.deleted_at IS NULL AND t.type = 'transfer' AND t.to_amount IS NOT NULL
  AND t.occurred_at < ?2 AND (t.currency = ?1) <> (a.currency = ?1)
GROUP BY 1''',
        variables: [Variable(mainCurrency), wallClockVariable(before)],
        readsFrom: {assetsAccountsTable, transactionsTable},
      ).watch().map(
        // SQLite fills the bare columns from the row holding MAX(occurred_at).
        (rows) => {
          for (final r in rows)
            r.read<String>('other'): r.read<String>('source') == mainCurrency
                ? rate(r.read<int>('amount'), r.read<int>('to_amount'))
                : rate(r.read<int>('to_amount'), r.read<int>('amount')),
        },
      );
}
