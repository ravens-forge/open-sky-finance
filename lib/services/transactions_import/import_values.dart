import '../../core/dates/wall_clock.dart';

/// Numbers and dates as other apps write them in CSV and QIF files.
abstract final class ImportValues {
  static final _numeric = RegExp(
    r"^(\d{1,4})\s*[/.\-']\s*(\d{1,2})\s*[/.\-']\s*(\d{1,4})",
  );
  static final _time = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?');

  /// Micro-units of "1,234.56", "-1.234,56", "1 234,5" or "(12.00)" (a
  /// negative amount); `null` when it is not a number. The last `.` or `,`
  /// followed by one to six digits at the end is the decimal mark.
  static int? amount(String text) {
    var t = text.replaceAll(RegExp(r'[\s  $€£¥]'), '');
    var negative = false;
    if (t.startsWith('(') && t.endsWith(')')) {
      negative = true;
      t = t.substring(1, t.length - 1);
    }
    if (t.startsWith('-') || t.startsWith('−')) {
      negative = !negative;
      t = t.substring(1);
    } else if (t.startsWith('+')) {
      t = t.substring(1);
    }
    if (t.isEmpty || !RegExp(r'^[\d.,]+$').hasMatch(t)) return null;
    final decimal = RegExp(r'[.,](\d{1,6})$').firstMatch(t);
    // "1.234" or "1,234": a thousands group, not decimals.
    final grouped =
        decimal != null &&
        decimal[1]!.length == 3 &&
        RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(t) &&
        !(t.contains('.') && t.contains(','));
    final whole =
        (decimal == null || grouped ? t : t.substring(0, decimal.start))
            .replaceAll(RegExp('[.,]'), '');
    final fraction = decimal == null || grouped ? '' : decimal[1]!;
    if (whole.isEmpty && fraction.isEmpty) return null;
    final micros =
        int.parse(whole.isEmpty ? '0' : whole) * 1000000 +
        int.parse(fraction.padRight(6, '0'));
    return negative ? -micros : micros;
  }

  /// "-54.3" → "-54.30": dot decimals, at least two, no grouping.
  static String formatAmount(int micros) {
    final sign = micros < 0 ? '-' : '';
    final abs = micros.abs();
    var fraction = '${abs % 1000000}'.padLeft(6, '0');
    while (fraction.length > 2 && fraction.endsWith('0')) {
      fraction = fraction.substring(0, fraction.length - 1);
    }
    return '$sign${abs ~/ 1000000}.$fraction';
  }

  /// Whether the dates of a file put the day first (31/12/2026): when one
  /// of them only reads that way; [fallback] when every one reads both
  /// ways. ISO dates (2026-12-31) say nothing.
  static bool dayFirst(Iterable<String> dates, {required bool fallback}) {
    for (final text in dates) {
      final m = _numeric.firstMatch(text.trim());
      if (m == null || m[1]!.length == 4) continue;
      if (int.parse(m[1]!) > 12) return true;
      if (int.parse(m[2]!) > 12) return false;
    }
    return fallback;
  }

  /// Wall-clock date and time of "2026-09-17", "2026-09-17T10:30:00",
  /// "17/09/2026 10:30", "9/17'26" (QIF) and the like; midnight when there
  /// is no time. `null` when it is not a date.
  static DateTime? date(String text, {required bool dayFirst}) {
    final t = text.trim();
    final iso = parseWallClock(t.replaceFirst(' ', 'T'));
    if (iso != null) return iso;
    final m = _numeric.firstMatch(t);
    if (m == null) return null;
    int year;
    int month;
    int day;
    if (m[1]!.length == 4) {
      (year, month, day) = (
        int.parse(m[1]!),
        int.parse(m[2]!),
        int.parse(m[3]!),
      );
    } else {
      final a = int.parse(m[1]!);
      final b = int.parse(m[2]!);
      (day, month) = dayFirst ? (a, b) : (b, a);
      year = int.parse(m[3]!);
      if (m[3]!.length <= 2) year += year < 70 ? 2000 : 1900;
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final time = _time.firstMatch(t.substring(m.end));
    final date = DateTime(
      year,
      month,
      day,
      int.tryParse(time?[1] ?? '') ?? 0,
      int.tryParse(time?[2] ?? '') ?? 0,
      int.tryParse(time?[3] ?? '') ?? 0,
    );
    // 31/02 rolls over into March: not a date.
    return date.month == month ? date : null;
  }
}
