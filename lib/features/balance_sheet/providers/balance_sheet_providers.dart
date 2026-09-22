import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/main_currency.dart';
import '../../../core/dates/wall_clock.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/providers.dart';
import '../../assets_accounts/models/assets_account_with_balance.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../models/balance_sheet_side.dart';

part 'balance_sheet_providers.g.dart';

/// Balance of every assets account as of the end of [asOf]'s day, in its own
/// currency, hidden ones included.
@riverpod
Stream<Map<String, int>> balanceSheetBalances(Ref ref, DateTime asOf) =>
    ref.watch(balancesRepositoryProvider).watchBalances(startOfNextDay(asOf));

/// The non-hidden assets accounts with their balance as of [asOf]; hidden
/// ones are left out entirely (the page shows a count and a link instead).
@riverpod
Future<List<AssetsAccountWithBalance>> balanceSheetAccounts(
  Ref ref,
  DateTime asOf,
) async {
  final accounts = await ref.watch(assetsAccountsProvider.future);
  final balances = await ref.watch(balanceSheetBalancesProvider(asOf).future);
  return [
    for (final a in accounts)
      if (!a.isHidden) AssetsAccountWithBalance(a, balances[a.id] ?? 0),
  ];
}

/// The Balance sheet page: assets and liabilities grouped by type, with
/// subtotals in the main currency, as of [asOf].
@riverpod
Future<List<BalanceSheetSide>> balanceSheetSides(Ref ref, DateTime asOf) async {
  final accounts = await ref.watch(balanceSheetAccountsProvider(asOf).future);
  final converter = await ref.watch(currencyConverterProvider.future);
  return groupBalanceSheet(accounts, converter);
}

/// How many assets accounts are hidden (left out of the sheet).
@riverpod
Future<int> balanceSheetHiddenCount(Ref ref) async {
  final accounts = await ref.watch(assetsAccountsProvider.future);
  return accounts.where((AssetsAccount a) => a.isHidden).length;
}
