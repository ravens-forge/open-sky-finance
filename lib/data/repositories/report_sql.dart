import 'package:drift/drift.dart';

import '../../core/dates/wall_clock.dart';

// SQL shared by the aggregations. Every aggregation skips trashed transactions
// and sums money per currency (convert totals with `CurrencyConverter`).
// Periods are `from <= occurred_at < to` (local wall-clock); "now" is the start
// of tomorrow, so scheduled transactions stay out of balances.

/// Home chart accounts: the favorites, or every non-hidden one when none is.
const chartAccountsCte = '''
chart_accounts AS (
  SELECT id, exclude_from_net_worth FROM assets_accounts
  WHERE is_favorite = 1 OR (is_hidden = 0
    AND NOT EXISTS (SELECT 1 FROM assets_accounts WHERE is_favorite = 1))
)''';

/// Each effect of a live transaction on an assets account, signed and in that
/// account's currency: a transfer is a move out of one and into the other.
const movesCte = '''
moves AS (
  SELECT t.assets_account_id AS assets_account_id, t.currency AS currency,
    t.occurred_at AS occurred_at,
    CASE WHEN t.type = 'transfer' THEN -t.amount ELSE t.amount END AS amount
  FROM transactions t WHERE t.deleted_at IS NULL
  UNION ALL
  SELECT t.to_assets_account_id, a.currency, t.occurred_at,
    COALESCE(t.to_amount, t.amount)
  FROM transactions t JOIN assets_accounts a ON a.id = t.to_assets_account_id
  WHERE t.deleted_at IS NULL AND t.type = 'transfer'
)''';

/// Hidden assets accounts are left out of totals.
const visibleAccounts =
    'assets_account_id IN (SELECT id FROM assets_accounts WHERE is_hidden = 0)';

Variable<String> wallClockVariable(DateTime date) =>
    Variable(formatWallClock(date));
