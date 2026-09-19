import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../models/onboarding_step.dart';
import '../widgets/basics_step.dart';
import '../widgets/first_assets_account_step.dart';
import '../widgets/onboarding_header.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/welcome_step.dart';

/// The pending onboarding steps, one per screen. The router leaves this page
/// once the session is finished.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  var _index = 0;
  OnboardingStep? _marked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(onboardingProvider).value;
    if (session == null || session.steps.isEmpty) return const Scaffold();

    final notifier = ref.read(onboardingProvider.notifier);
    final steps = session.steps;
    final index = _index.clamp(0, steps.length - 1);
    final step = steps[index];
    // Seen as soon as displayed, so a restart resumes at the next one.
    if (_marked != step) {
      _marked = step;
      unawaited(notifier.markSeen(step));
    }
    void next() => index == steps.length - 1
        ? unawaited(notifier.finish())
        : setState(() => _index = index + 1);
    final back = index == 0 ? null : () => setState(() => _index = index - 1);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              session.whatsNew
                  ? OnboardingHeader(
                      label: l10n.onboardingWhatsNew,
                      onSkip: notifier.finish,
                    )
                  : OnboardingHeader(
                      label: l10n.onboardingStepOf(index + 1, steps.length),
                      step: index + 1,
                      total: steps.length,
                      onSkip: notifier.finish,
                    ),
              if (session.whatsNew)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    l10n.onboardingNewIn(step.sinceLabel).toUpperCase(),
                    style: Theme.of(context).textTheme.eyebrow,
                  ),
                ),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey(step.id),
                  child: switch (step) {
                    OnboardingStep.welcome => WelcomeStep(onNext: next),
                    OnboardingStep.basics => BasicsStep(
                      onNext: next,
                      onBack: back,
                    ),
                    OnboardingStep.firstAssetsAccount => FirstAssetsAccountStep(
                      onSkip: next,
                    ),
                    // Every step in onboardingSteps has a screen above.
                    _ => throw StateError('No screen for ${step.id}'),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
