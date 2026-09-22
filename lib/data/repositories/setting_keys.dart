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
}
