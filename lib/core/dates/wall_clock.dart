final _wallClock = RegExp(
  r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(:\d{2}(\.\d{1,6})?)?$',
);

/// Midnight at the start of [date]'s day.
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

/// Midnight at the end of [date]'s day.
DateTime startOfNextDay(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);

/// The last microsecond of [date]'s day.
DateTime endOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 999);

/// Formats [date] as ISO-8601 without offset, to the second: `2026-03-14T18:30:00`.
String formatWallClock(DateTime date) =>
    date.toIso8601String().substring(0, 19);

/// Parses `yyyy-MM-ddTHH:mm[:ss]` (or with a space instead of `T`) as a local
/// wall-clock time. Returns `null` for anything else, including values with an offset.
DateTime? parseWallClock(String text) =>
    _wallClock.hasMatch(text) ? DateTime.tryParse(text) : null;

/// Upper-cases the first character, for headings built from `DateFormat` output
/// (`septiembre de 2026` → `Septiembre de 2026`). Month and weekday names are
/// lower-case in es and fr and must stay so inside a sentence.
String capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  final first = String.fromCharCode(text.runes.first);
  return '${first.toUpperCase()}${text.substring(first.length)}';
}
