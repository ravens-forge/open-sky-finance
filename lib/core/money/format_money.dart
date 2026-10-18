import 'package:intl/intl.dart';

/// Micro-units per currency unit (`1.00` = `1_000_000`).
const microsPerUnit = 1000000;

final _lastDigit = RegExp('[0-9](?!.*[0-9])');

/// A letter symbol glued to the number (`CHF18.00`).
final _gluedCode = RegExp('^([A-Za-z]+)([0-9])');

/// Formats [micros] as a currency amount in [locale], e.g. `€1,234.56` (en) or
/// `1 234,56 €` (fr).
///
/// Shows the currency's usual decimals (2 for EUR, 0 for JPY) and up to 6 when the
/// amount has more precision, so a stored value is never shown rounded.
///
/// With `symbol: false` only the number is returned (`1 234,56`), for screen reader
/// labels that say the currency name instead. With `code: true` the ISO code
/// stands in for the symbol (`ARS 1,250.00`), for amounts shown next to another
/// currency with the same symbol (see [sharedSymbols]).
String formatMoney(
  int micros, {
  required String currency,
  required String locale,
  bool symbol = true,
  bool code = false,
}) {
  final format = !symbol
      ? NumberFormat.currency(locale: locale, name: currency, symbol: '')
      : code
      ? NumberFormat.currency(locale: locale, name: currency)
      : NumberFormat.simpleCurrency(locale: locale, name: currency);
  final symbols = format.symbols;
  final digits = format.decimalDigits ?? 2;
  final abs = micros.abs();

  // Integer part through intl (symbol position, grouping), fraction from the int:
  // no double, so every amount stays exact.
  var fraction = (abs % microsPerUnit).toString().padLeft(6, '0');
  while (fraction.length > digits && fraction.endsWith('0')) {
    fraction = fraction.substring(0, fraction.length - 1);
  }
  format
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = 0;

  var text = format
      .format(abs ~/ microsPerUnit)
      .trim()
      .replaceFirstMapped(_gluedCode, (m) => '${m[1]}\u00A0${m[2]}');
  if (fraction.isNotEmpty) {
    final end = _lastDigit.firstMatch(text)!.end;
    text =
        '${text.substring(0, end)}${symbols.DECIMAL_SEP}$fraction'
        '${text.substring(end)}';
  }
  // en, es and fr all put the minus sign first.
  return micros < 0 ? '${symbols.MINUS_SIGN}$text' : text;
}

/// The currencies of [currencies] whose usual symbol another of them shares
/// (`$` for USD and ARS, `kr` for SEK and NOK): shown together, they need
/// their ISO code to be told apart.
Set<String> sharedSymbols(Iterable<String> currencies, String locale) {
  final bySymbol = <String, List<String>>{};
  for (final c in {...currencies}) {
    final symbol = NumberFormat.simpleCurrency(
      locale: locale,
      name: c,
    ).currencySymbol;
    (bySymbol[symbol] ??= []).add(c);
  }
  return {
    for (final same in bySymbol.values)
      if (same.length > 1) ...same,
  };
}
