import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/main_currency.dart';
import '../../../core/dates/wall_clock.dart';
import '../../../core/money/currency_converter.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/providers.dart';
import '../models/assets_account_with_balance.dart';
import '../models/assets_accounts_side.dart';

part 'assets_accounts_providers.g.dart';

/// Every assets account, hidden ones included, in sort order.
@riverpod
Stream<List<AssetsAccount>> assetsAccounts(Ref ref) =>
    ref.watch(assetsAccountsRepositoryProvider).watchAll();

/// Balance of every assets account as of today, in its own currency.
@riverpod
Stream<Map<String, int>> assetsAccountBalances(Ref ref) =>
    ref.watch(balancesRepositoryProvider).watchBalances(startOfTomorrow());

@riverpod
Future<List<AssetsAccountWithBalance>> assetsAccountsWithBalance(
  Ref ref,
) async {
  final accounts = await ref.watch(assetsAccountsProvider.future);
  final balances = await ref.watch(assetsAccountBalancesProvider.future);
  return [
    for (final a in accounts) AssetsAccountWithBalance(a, balances[a.id] ?? 0),
  ];
}

/// Units of the main currency per unit of each other currency, as of today.
@riverpod
Stream<Map<String, Decimal>> exchangeRates(Ref ref) async* {
  final main = await ref.watch(mainCurrencyProvider.future);
  yield* ref
      .watch(exchangeRatesRepositoryProvider)
      .watchRates(main, startOfTomorrow());
}

/// The Assets accounts page: assets and liabilities grouped by type, with
/// subtotals in the main currency.
@riverpod
Future<List<AssetsAccountsSide>> assetsAccountsSides(
  Ref ref,
  bool showHidden,
) async {
  final accounts = await ref.watch(assetsAccountsWithBalanceProvider.future);
  final converter = CurrencyConverter(
    await ref.watch(mainCurrencyProvider.future),
    await ref.watch(exchangeRatesProvider.future),
  );
  return groupAssetsAccounts([
    for (final a in accounts)
      if (showHidden || !a.account.isHidden) a,
  ], converter);
}
