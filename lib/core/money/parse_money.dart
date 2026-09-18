import 'package:intl/intl.dart';

import 'format_money.dart';

/// Largest absolute amount accepted, in micro-units (exact in JSON/JavaScript).
const maxMicros = 9007199254740991;

final _ignored = RegExp(r'[\s  \p{Sc}]', unicode: true);
final _minusSigns = RegExp('^[-−]');
final _number = RegExp(r'^[0-9.,]+$');

/// Parses user input in [locale] into micro-units, or returns `null` when the input
/// is not a valid amount.
///
/// Accepts the locale's separators (`1,234.56` en, `1.234,56` es, `1 234,56` fr),
/// ignores spaces and currency symbols, and accepts a leading minus. The other decimal
/// separator is accepted when it cannot be a group separator (`12.5` in fr is 12.50);
/// input that could be read both ways (`1.234` in fr) is rejected. More than 6 decimals
/// or amounts above [maxMicros] are rejected.
int? parseMoney(String input, {required String locale}) {
  final symbols = NumberFormat.decimalPattern(locale).symbols;
  final decimal = symbols.DECIMAL_SEP;
  // fr groups with a (narrow) no-break space, which is stripped with other spaces.
  final group = symbols.GROUP_SEP.trim().isEmpty ? null : symbols.GROUP_SEP;
  final other = decimal == '.' ? ',' : '.';

  var text = input.replaceAll(_ignored, '');
  final negative = _minusSigns.hasMatch(text);
  if (negative) text = text.substring(1);
  if (!_number.hasMatch(text)) return null;

  String integer;
  String fraction;
  final parts = text.split(decimal);
  if (parts.length > 2) return null;
  if (parts.length == 2) {
    integer = parts[0];
    fraction = parts[1];
    if (fraction.contains(other)) return null;
    if (integer.contains(other)) {
      if (other != group || !_isGrouped(integer, other)) return null;
      integer = integer.replaceAll(other, '');
    }
    if (integer.isEmpty && fraction.isEmpty) return null;
  } else if (!text.contains(other)) {
    integer = text;
    fraction = '';
  } else if (_isGrouped(text, other)) {
    // `1,234` is a thousand in en but ambiguous in fr, which never groups with `.`.
    if (other != group) return null;
    integer = text.replaceAll(other, '');
    fraction = '';
  } else {
    // Tolerant rule: a single other separator is a decimal separator.
    final split = text.split(other);
    if (split.length != 2 || split[1].isEmpty) return null;
    integer = split[0];
    fraction = split[1];
  }

  if (fraction.length > 6) return null;
  final units = int.tryParse(integer.isEmpty ? '0' : integer);
  if (units == null || units > maxMicros ~/ microsPerUnit) return null;
  final micros = units * microsPerUnit + int.parse(fraction.padRight(6, '0'));
  if (micros > maxMicros) return null;
  return negative ? -micros : micros;
}

/// Whether [text] is digits grouped by thousands with [separator] (`1,234,567`).
bool _isGrouped(String text, String separator) {
  final groups = text.split(separator);
  return groups.length > 1 &&
      RegExp(r'^[1-9]\d{0,2}$').hasMatch(groups.first) &&
      groups.skip(1).every((g) => g.length == 3);
}
