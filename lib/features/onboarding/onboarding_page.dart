import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/widgets/app_logo.dart';
import '../../data/providers.dart';
import 'onboarding_pending.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(height: AppLogo.welcomeHeight),
              const SizedBox(height: 16),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const Spacer(),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () =>
                      skipOnboarding(ref.read(settingsRepositoryProvider)),
                  child: Text(l10n.actionSkip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
