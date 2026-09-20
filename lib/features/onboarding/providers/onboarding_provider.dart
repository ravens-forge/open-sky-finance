import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result.dart';
import '../../../data/repositories/setting_keys.dart';
import '../../../data/models/assets_account_draft.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/repository_data_error.dart';
import '../models/onboarding_session.dart';
import '../models/onboarding_step.dart';
import '../models/onboarding_steps.dart';

part 'onboarding_provider.g.dart';

/// Pending onboarding steps, computed once per app start so marking a step
/// as seen while it is shown does not end the session.
@Riverpod(keepAlive: true)
class Onboarding extends _$Onboarding {
  @override
  Future<OnboardingSession> build() async {
    final seen = await _seen();
    final plan = planOnboarding(
      seen,
      hasUserData: await ref.watch(transactionsRepositoryProvider).hasAny(),
    );
    if (plan.autoSeen.isNotEmpty) await _addSeen(plan.autoSeen);
    return OnboardingSession(
      plan.pending,
      whatsNew:
          plan.pending.isNotEmpty && plan.pending.every((s) => !s.newUsersOnly),
    );
  }

  /// Called as soon as [step] is displayed.
  Future<void> markSeen(OnboardingStep step) => _addSeen([step.id]);

  /// Skip, or the last step is done: every step of this session is seen.
  Future<void> finish() async {
    await _addSeen([
      for (final s in state.value?.steps ?? const <OnboardingStep>[]) s.id,
    ]);
    state = const AsyncData(OnboardingSession.done);
  }

  /// Creates the first assets account, makes its currency the main currency
  /// and finishes.
  Future<Result<String, RepositoryDataError>> createFirstAssetsAccount(
    AssetsAccountDraft draft,
  ) async {
    final result = await ref.read(appDatabaseProvider).transaction(() async {
      final result = await ref
          .read(assetsAccountsRepositoryProvider)
          .save(draft);
      if (result is Ok) {
        await ref
            .read(settingsRepositoryProvider)
            .set(SettingKeys.mainCurrency, draft.currency);
      }
      return result;
    });
    if (result is Ok) await finish();
    return result;
  }

  Future<Set<String>?> _seen() async {
    final json = await ref
        .read(settingsRepositoryProvider)
        .get(SettingKeys.onboardingSeenSteps);
    return json == null
        ? null
        : (jsonDecode(json) as List<Object?>).whereType<String>().toSet();
  }

  Future<void> _addSeen(Iterable<String> ids) async {
    final seen = {...?await _seen(), ...ids};
    await ref
        .read(settingsRepositoryProvider)
        .set(SettingKeys.onboardingSeenSteps, jsonEncode(seen.toList()));
  }
}
