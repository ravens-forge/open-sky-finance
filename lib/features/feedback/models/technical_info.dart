class TechnicalInfo {
  const TechnicalInfo({
    required this.version,
    required this.build,
    required this.platform,
    required this.language,
    required this.schemaVersion,
  });

  /// e.g. `1.0.0`.
  final String version;

  /// e.g. `42`.
  final String build;

  /// Platform and OS version, e.g. `Android 15`.
  final String platform;

  /// Language code of the app, e.g. `en`.
  final String language;

  /// Drift `schemaVersion` of the database.
  final int schemaVersion;

  String get versionAndBuild => '$version ($build)';

  /// Values keyed by the field ids of the GitHub issue forms.
  Map<String, String> get formFields => {
    'app_version': versionAndBuild,
    'platform': platform,
    'language': language,
    'schema_version': '$schemaVersion',
  };
}
