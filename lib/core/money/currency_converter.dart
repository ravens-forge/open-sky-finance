import 'package:decimal/decimal.dart';

/// Units received per unit paid, from two amounts exchanged for each other.
Decimal rate(int received, int paid) =>
    (Decimal.fromInt(received) / Decimal.fromInt(paid)).toDecimal(
      scaleOnInfinitePrecision: 20,
    );

/// A total in the main currency. A display value: never store it.
class ConvertedTotal {
  const ConvertedTotal(
    this.amount, {
    required this.approximate,
    required this.notIncluded,
  });

  /// Micro-units of the main currency.
  final int amount;

  /// Another currency was converted into [amount]: show it with "≈".
  final bool approximate;

  /// Amounts left out of [amount] because their currency has no rate yet
  /// ("Not included").
  final Map<String, int> notIncluded;
}

/// Converts totals into [mainCurrency] with [rates] (units of the main currency
/// per unit of another, see `ReportsDao.watchRates`).
class CurrencyConverter {
  const CurrencyConverter(this.mainCurrency, this.rates);

  final String mainCurrency;
  final Map<String, Decimal> rates;

  /// Converts each amount exactly and rounds the sum half-even to micro-units.
  ConvertedTotal convert(Map<String, int> amounts) {
    var sum = Decimal.zero;
    var approximate = false;
    final notIncluded = <String, int>{};
    for (final MapEntry(key: currency, value: micros) in amounts.entries) {
      if (micros == 0) continue;
      if (currency == mainCurrency) {
        sum += Decimal.fromInt(micros);
      } else if (rates[currency] case final rate?) {
        sum += Decimal.fromInt(micros) * rate;
        approximate = true;
      } else {
        notIncluded[currency] = micros;
      }
    }
    return ConvertedTotal(
      _roundHalfEven(sum),
      approximate: approximate,
      notIncluded: notIncluded,
    );
  }
}

final _half = Decimal.parse('0.5');

int _roundHalfEven(Decimal value) {
  final floor = value.floor();
  final fraction = value - floor;
  var result = floor.toBigInt();
  if (fraction > _half || (fraction == _half && result.isOdd)) {
    result += BigInt.one;
  }
  return result.toInt();
}
