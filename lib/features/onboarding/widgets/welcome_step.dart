import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/point_row.dart';
import 'onboarding_step_layout.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final headline = theme.textTheme.displayMedium!.copyWith(fontSize: 40);
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
        PointRow(
          icon: Icons.lock_outline,
          title: l10n.welcomeOfflineTitle,
          body: l10n.welcomeOfflineBody,
        ),
        PointRow(
          icon: Icons.favorite_border,
          title: l10n.welcomeNoAdsTitle,
          body: l10n.welcomeNoAdsBody,
        ),
        PointRow(
          icon: Icons.cloud_outlined,
          title: l10n.welcomeBackupsTitle,
          body: l10n.welcomeBackupsBody,
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
