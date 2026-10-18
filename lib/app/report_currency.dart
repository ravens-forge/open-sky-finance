import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/money/currency_order.dart';
import '../data/models/assets_account.dart';
import '../data/providers.dart';
import 'default_currency.dart';

part 'report_currency.g.dart';

/// Currencies of the non-hidden assets accounts with how many use each, in
/// display order (the default currency first, then by code).
@riverpod
Stream<Map<String, int>> reportCurrencies(Ref ref) async* {
  final fallback = await ref.watch(defaultCurrencyProvider.future);
  yield* ref
      .watch(assetsAccountsRepositoryProvider)
      .watchAll()
      .map((accounts) => usedCurrencies(accounts, fallback));
}

Map<String, int> usedCurrencies(
  List<AssetsAccount> accounts,
  String defaultCurrency,
) {
  final counts = <String, int>{};
  for (final a in accounts) {
    if (!a.isHidden) counts[a.currency] = (counts[a.currency] ?? 0) + 1;
  }
  return {
    for (final c in orderCurrencies(counts.keys, defaultCurrency))
      c: counts[c]!,
  };
}

/// The currency the user picked for reports, shared by all of them until
/// the app closes; `null` until they pick one.
@Riverpod(keepAlive: true)
class ReportCurrencyChoice extends _$ReportCurrencyChoice {
  @override
  String? build() => null;

  void pick(String currency) => state = currency;
}

/// The one currency reports (Home, Balance sheet, Net income, Calendar)
/// show: the picked one while an assets account uses it, else the default
/// currency when one does, else the first one used. Nothing is converted.
@riverpod
Future<String> reportCurrency(Ref ref) async {
  final used = await ref.watch(reportCurrenciesProvider.future);
  final fallback = await ref.watch(defaultCurrencyProvider.future);
  final picked = ref.watch(reportCurrencyChoiceProvider);
  if (picked != null && used.containsKey(picked)) return picked;
  if (used.isEmpty || used.containsKey(fallback)) return fallback;
  return used.keys.first;
}
