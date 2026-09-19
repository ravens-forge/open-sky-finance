import 'onboarding_step.dart';

/// Every step, in display order.
const onboardingSteps = [
  OnboardingStep.welcome,
  OnboardingStep.basics,
  OnboardingStep.firstAssetsAccount,
];

/// What to do on start. [autoSeen]: new-users-only steps to mark as seen
/// without showing them, because the user already uses the app (has data, or
/// saw a step older than them). [pending]: the steps to show, in order.
/// Unknown ids in [seen] are ignored.
({Set<String> autoSeen, List<OnboardingStep> pending}) planOnboarding(
  Set<String>? seen, {
  required bool hasUserData,
  List<OnboardingStep> steps = onboardingSteps,
}) {
  final known = seen ?? const {};
  bool existingUserFor(OnboardingStep step) =>
      hasUserData ||
      steps.any((s) => known.contains(s.id) && s.isOlderThan(step));
  final autoSeen = {
    for (final s in steps)
      if (s.newUsersOnly && !known.contains(s.id) && existingUserFor(s)) s.id,
  };
  return (
    autoSeen: autoSeen,
    pending: [
      for (final s in steps)
        if (!known.contains(s.id) && !autoSeen.contains(s.id)) s,
    ],
  );
}
