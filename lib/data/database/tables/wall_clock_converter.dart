import 'package:drift/drift.dart';

import '../../../core/dates/wall_clock.dart';

/// Local wall-clock date-times as ISO-8601 text without offset
/// (`2026-03-14T18:30:00`), so they sort and compare as text. Drift's own
/// `dateTime()` would append the device offset.
class WallClockConverter extends TypeConverter<DateTime, String> {
  const WallClockConverter();

  @override
  DateTime fromSql(String fromDb) => parseWallClock(fromDb)!;

  @override
  String toSql(DateTime value) => formatWallClock(value);
}
