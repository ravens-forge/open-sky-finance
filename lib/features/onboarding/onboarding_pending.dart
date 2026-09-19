import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/tables/setting_keys.dart';
import '../../data/providers.dart';
import '../../data/repositories/settings_repository.dart';
import 'onboarding_steps.dart';

part 'onboarding_pending.g.dart';

/// Whether some onboarding step has not been seen yet.
@Riverpod(keepAlive: true)
Stream<bool> onboardingPending(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.onboardingSeenSteps)
    .map((json) {
      final seen = json == null
          ? const <Object?>{}
          : (jsonDecode(json) as List<Object?>).toSet();
      return onboardingSteps.any((id) => !seen.contains(id));
    });

/// Marks every step as seen (Skip).
Future<void> skipOnboarding(SettingsRepository settings) =>
    settings.set(SettingKeys.onboardingSeenSteps, jsonEncode(onboardingSteps));
