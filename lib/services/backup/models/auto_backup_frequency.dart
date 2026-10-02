enum AutoBackupFrequency {
  daily,
  weekly,
  monthly;

  /// When the backup after one made [at] is due: a day, a week or a calendar
  /// month later (31 Jan → 28 Feb).
  DateTime next(DateTime at) => switch (this) {
    daily => DateTime(at.year, at.month, at.day + 1, at.hour, at.minute),
    weekly => DateTime(at.year, at.month, at.day + 7, at.hour, at.minute),
    monthly => DateTime(
      at.year,
      at.month + 1,
      // Day 0 of the month after is the last day of the next month.
      at.day.clamp(1, DateTime(at.year, at.month + 2, 0).day),
      at.hour,
      at.minute,
    ),
  };
}
