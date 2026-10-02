/// Keys of the `settings` table. Values are plain strings or JSON.
abstract final class SettingKeys {
  static const themeMode = 'theme_mode';

  /// `en`, `es` or `fr`; missing = follow the device.
  static const locale = 'locale';

  /// ISO 4217 code totals are shown in.
  static const mainCurrency = 'main_currency';
  static const firstDayOfWeek = 'first_day_of_week';
  static const homeSections = 'home_sections';

  /// Months shown by the Home charts: `6` (default) or `12`.
  static const homeChartMonths = 'home_chart_months';
  static const onboardingSeenSteps = 'onboarding_seen_steps';

  /// `true` while automatic backups run. Device-only.
  static const autoBackupEnabled = 'auto_backup_enabled';

  /// The granted folder: an Android tree URI or an iOS bookmark. Device-only.
  static const autoBackupFolder = 'auto_backup_folder';

  /// The folder's name as the system shows it. Device-only.
  static const autoBackupFolderName = 'auto_backup_folder_name';

  /// `daily`, `weekly` (default) or `monthly`. Device-only.
  static const autoBackupFrequency = 'auto_backup_frequency';

  /// How many automatic backups the folder keeps (default 10). Device-only.
  static const autoBackupKeep = 'auto_backup_keep';

  /// `true` once the folder could not be reached: automatic backups wait
  /// until a folder is picked again. Device-only.
  static const autoBackupPaused = 'auto_backup_paused';

  /// The key backups are encrypted with (JSON: salt, key and Argon2id
  /// costs), missing when they are not. Device-only.
  static const backupKey = 'backup_key';

  /// `true` when a notification says a budget is used up. Device-only.
  static const budgetAlerts = 'budget_alerts';

  /// JSON map of budget owner id → the month (`2026-09`) it was last alerted
  /// for. Device-only.
  static const budgetAlertsSent = 'budget_alerts_sent';

  /// UTC instant (ISO 8601) of the last backup. Device-only.
  static const lastBackupAt = 'last_backup_at';

  /// Where the last backup went: `saved`, `shared` or `automatic`.
  /// Device-only.
  static const lastBackupDestination = 'last_backup_destination';

  /// Size in bytes of the last backup file. Device-only.
  static const lastBackupSize = 'last_backup_size';

  /// Preferences written into backup files, and replaced by a restore; the
  /// rest belong to the device.
  static const backedUp = [
    mainCurrency,
    themeMode,
    locale,
    firstDayOfWeek,
    homeSections,
  ];

  /// Preferences that survive "Erase all data"; every other key is removed.
  static const keptOnErase = [themeMode, locale, firstDayOfWeek];
}
