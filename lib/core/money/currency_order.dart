/// Lines of a multi-currency total shown before "+N more currencies".
const foldedCurrencies = 3;

/// [currencies] once each in display order: [defaultCurrency] first, then
/// the others by code.
List<String> orderCurrencies(
  Iterable<String> currencies,
  String defaultCurrency,
) => {...currencies}.toList()
  ..sort(
    (a, b) => a == defaultCurrency
        ? -1
        : b == defaultCurrency
        ? 1
        : a.compareTo(b),
  );

/// The non-zero amounts of [totals] in display order. When none is left,
/// zero in its first currency, or in [defaultCurrency] when it has none.
/// Nothing is converted.
List<MapEntry<String, int>> totalsInOrder(
  Map<String, int> totals,
  String defaultCurrency,
) {
  final order = orderCurrencies(totals.keys, defaultCurrency);
  final shown = [
    for (final currency in order)
      if (totals[currency]! != 0) MapEntry(currency, totals[currency]!),
  ];
  if (shown.isNotEmpty) return shown;
  return [MapEntry(order.firstOrNull ?? defaultCurrency, 0)];
}
