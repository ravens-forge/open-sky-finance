/// What an automatic backup run did.
enum AutoBackupResult {
  /// Turned off, paused or without a folder.
  off,

  /// The last backup is newer than the frequency.
  notDue,
  done,

  /// The backup could not be made; nothing changed.
  failed,

  /// The folder could not be reached: automatic backups are paused now.
  paused,
}
