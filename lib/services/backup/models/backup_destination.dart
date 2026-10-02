enum BackupDestination {
  /// Save to…: a file the user placed with the system save dialog.
  saved,

  /// Share…: handed to another app through the share sheet.
  shared,

  /// Automatic: written into the folder the user granted.
  automatic,
}
