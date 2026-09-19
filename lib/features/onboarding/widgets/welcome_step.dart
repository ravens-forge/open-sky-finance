import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/app_logo.dart';
import 'onboarding_step_layout.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final headline = theme.textTheme.displayMedium!.copyWith(fontSize: 40);
    Widget point(IconData icon, String title, String body) => Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(title, style: theme.textTheme.labelLarge),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return OnboardingStepLayout(
      actions: [FilledButton(onPressed: onNext, child: Text(l10n.actionNext))],
      children: [
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppLogo(height: AppLogo.welcomeHeight),
        ),
        const SizedBox(height: 22),
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${l10n.welcomeTitle}\n'),
                TextSpan(
                  text: l10n.welcomeTitleEmphasis,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            style: headline,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.welcomeIntro,
          style: theme.textTheme.bodyLarge!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        point(
          Icons.lock_outline,
          l10n.welcomeOfflineTitle,
          l10n.welcomeOfflineBody,
        ),
        point(
          Icons.favorite_border,
          l10n.welcomeNoAdsTitle,
          l10n.welcomeNoAdsBody,
        ),
        point(
          Icons.cloud_outlined,
          l10n.welcomeBackupsTitle,
          l10n.welcomeBackupsBody,
        ),
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
            child: Text(l10n.welcomeRestoreLink),
          ),
        ),
      ],
    );
  }
}
