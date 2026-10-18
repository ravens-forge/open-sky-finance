import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/report_currency.dart';
import '../../../core/dates/wall_clock.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/setting_keys.dart';
import '../../assets_accounts/models/assets_account_with_balance.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../models/balance_sheet_baseline.dart';
import '../models/balance_sheet_comparison.dart';
import '../models/balance_sheet_side.dart';

part 'balance_sheet_providers.g.dart';

/// Balance of every assets account as of the end of [asOf]'s day, in its own
/// currency, hidden ones included.
@riverpod
Stream<Map<String, int>> balanceSheetBalances(Ref ref, DateTime asOf) =>
    ref.watch(balancesRepositoryProvider).watchBalances(startOfNextDay(asOf));

/// The non-hidden assets accounts in the report currency with their balance
/// as of [asOf]; hidden ones are left out entirely (the page shows a count
/// and a link instead), other currencies are never converted.
@riverpod
Future<List<AssetsAccountWithBalance>> balanceSheetAccounts(
  Ref ref,
  DateTime asOf,
) async {
  final accounts = await ref.watch(assetsAccountsProvider.future);
  final balances = await ref.watch(balanceSheetBalancesProvider(asOf).future);
  final currency = await ref.watch(reportCurrencyProvider.future);
  return [
    for (final a in accounts)
      if (!a.isHidden && a.currency == currency)
        AssetsAccountWithBalance(a, balances[a.id] ?? 0),
  ];
}

/// The Balance sheet page: assets and liabilities grouped by type, with
/// subtotals in the report currency, as of [asOf].
@riverpod
Future<List<BalanceSheetSide>> balanceSheetSides(
  Ref ref,
  DateTime asOf,
) async => groupBalanceSheet(
  await ref.watch(balanceSheetAccountsProvider(asOf).future),
);

/// How many assets accounts are hidden (left out of the sheet).
@riverpod
Future<int> balanceSheetHiddenCount(Ref ref) async {
  final accounts = await ref.watch(assetsAccountsProvider.future);
  return accounts.where((AssetsAccount a) => a.isHidden).length;
}

/// The date the Balance sheet compares with, kept between visits.
@riverpod
Stream<BalanceSheetComparison> balanceSheetComparison(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.balanceSheetComparison)
    .map(BalanceSheetComparison.decode);

/// Net worth and balances at the end of [date], to compare with.
@riverpod
Future<BalanceSheetBaseline> balanceSheetBaseline(
  Ref ref,
  DateTime date,
) async {
  final sides = await ref.watch(balanceSheetSidesProvider(date).future);
  final balances = await ref.watch(balanceSheetBalancesProvider(date).future);
  return BalanceSheetBaseline(
    date: date,
    netWorth: sides.fold(0, (sum, side) => sum + side.total),
    balances: balances,
  );
}
