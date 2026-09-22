import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/locale.dart';
import '../../../app/theme_mode.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/field_row.dart';
import '../../settings/widgets/preference_pickers.dart';
import 'onboarding_step_layout.dart';

/// Language, theme and first day of week, pre-filled from the device and
/// saved as soon as they change.
class BasicsStep extends ConsumerWidget {
  const BasicsStep({super.key, required this.onNext, this.onBack});

  final VoidCallback onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = ref.watch(userLocaleProvider).value;
    final themeMode = ref.watch(appThemeModeProvider).value ?? ThemeMode.system;
    final firstDay = firstDayOfWeek(context, ref);

    return OnboardingStepLayout(
      actions: [
        if (onBack != null)
          OutlinedButton(onPressed: onBack, child: Text(l10n.actionBack)),
        FilledButton(onPressed: onNext, child: Text(l10n.actionNext)),
      ],
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.basicsTitle,
            style: theme.textTheme.displayMedium!.copyWith(fontSize: 36),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.basicsIntro,
          style: theme.textTheme.bodyLarge!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        FieldRow(
          label: l10n.settingsLanguage,
          value: languageLabel(l10n, locale),
          onTap: () => pickLanguage(context, ref),
        ),
        FieldRow(
          label: l10n.settingsTheme,
          value: themeMode.label(l10n),
          onTap: () => pickThemeMode(context, ref),
        ),
        FieldRow(
          label: l10n.settingsFirstDayOfWeek,
          value: weekdayLabel(l10n, firstDay),
          onTap: () => pickFirstDayOfWeek(context, ref, firstDay),
        ),
      ],
    );
  }
}
