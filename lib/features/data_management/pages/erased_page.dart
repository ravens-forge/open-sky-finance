import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/point_row.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/onboarding_step_layout.dart';
import '../providers/erase_controller.dart';

/// Shown once after "Erase all data", alone on the navigation stack: what
/// was deleted, what is ready and what was kept.
class ErasedPage extends ConsumerWidget {
  const ErasedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final counts = ref.watch(eraseControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: AlignmentDirectional.centerStart,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  l10n.pageErased.toUpperCase(),
                  style: theme.textTheme.eyebrow,
                ),
              ),
              Expanded(
                child: OnboardingStepLayout(
                  actions: [
                    FilledButton(
                      // The onboarding plans its steps again and the router
                      // opens it.
                      onPressed: () => ref.invalidate(onboardingProvider),
                      child: Text(l10n.erasedStartSetup),
                    ),
                  ],
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surfaceContainerHigh,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.erasedTitle,
                        style: theme.textTheme.displayMedium!.copyWith(
                          fontSize: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      counts == null
                          ? l10n.erasedSummaryAll
                          : l10n.erasedSummary(
                              counts.assetsAccounts,
                              counts.transactions,
                            ),
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    PointRow(
                      icon: Icons.account_balance_wallet_outlined,
                      title: l10n.erasedReadyTitle,
                      body: l10n.erasedReadyBody,
                    ),
                    PointRow(
                      icon: Icons.tune,
                      title: l10n.erasedKeptTitle,
                      body: l10n.erasedKeptBody,
                    ),
                    PointRow(
                      icon: Icons.cloud_outlined,
                      title: l10n.erasedBackupsTitle,
                      body: l10n.erasedBackupsBody,
                    ),
                    const Divider(),
                    const Spacer(),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => context.push(Routes.backups),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          padding: EdgeInsets.zero,
                          textStyle: theme.textTheme.labelLarge!.copyWith(
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        child: Text(l10n.erasedRestore),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
