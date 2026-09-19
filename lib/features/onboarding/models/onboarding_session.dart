import 'package:flutter/foundation.dart';

import 'onboarding_step.dart';

/// The onboarding steps to show since this app start. Empty when done.
@immutable
class OnboardingSession {
  const OnboardingSession(this.steps, {required this.whatsNew});

  static const done = OnboardingSession([], whatsNew: false);

  final List<OnboardingStep> steps;

  /// Only steps added by an update: "What's new" instead of "Step X of Y".
  final bool whatsNew;
}
