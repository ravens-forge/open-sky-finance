/// One onboarding screen. [id] is stored in `onboarding_seen_steps`: never
/// rename it. [since] is the app version (major, minor) that added the step.
class OnboardingStep {
  const OnboardingStep(this.id, this.since, {this.newUsersOnly = false});

  final String id;
  final (int, int) since;

  /// Introductory: never shown to someone who already uses the app.
  final bool newUsersOnly;

  String get sinceLabel => '${since.$1}.${since.$2}';

  bool isOlderThan(OnboardingStep other) =>
      since.$1 < other.since.$1 ||
      (since.$1 == other.since.$1 && since.$2 < other.since.$2);

  static const welcome = OnboardingStep('welcome', (1, 0), newUsersOnly: true);
  static const basics = OnboardingStep('basics', (1, 0), newUsersOnly: true);
  static const firstAssetsAccount = OnboardingStep('firstAssetsAccount', (
    1,
    0,
  ), newUsersOnly: true);
}
