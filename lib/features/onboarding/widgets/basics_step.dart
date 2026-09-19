import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/first_day_of_week.dart';
import '../../../app/locale.dart';
import '../../../app/theme_mode.dart';
import '../../../core/dates/wall_clock.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/field_row.dart';
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
    final firstDay =
        ref.watch(firstDayOfWeekProvider).value ?? _localeFirstDay(context);

    // Without a choice the app follows the device, resolved like MaterialApp.
    final system = basicLocaleListResolution(
      WidgetsBinding.instance.platformDispatcher.locales,
      AppLocalizations.supportedLocales,
    );
    String languageLabel(Locale? l) => l == null
        ? l10n.settingsLanguageSystem(languageEndonyms[system.languageCode]!)
        : languageEndonyms[l.languageCode]!;
    // 1 January 2024 was a Monday.
    String dayLabel(int day) => capitalizeFirst(
      DateFormat.EEEE(l10n.localeName).format(DateTime(2024, 1, day)),
    );

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
          value: languageLabel(locale),
          onTap: () async {
            // '' is "System": the sheet returns null when dismissed.
            final picked = await showChoiceSheet(
              context,
              title: l10n.settingsLanguage,
              selected: locale?.languageCode ?? '',
              options: [
                ('', languageLabel(null)),
                for (final l in AppLocalizations.supportedLocales)
                  (l.languageCode, languageLabel(l)),
              ],
            );
            if (picked != null) {
              await ref
                  .read(userLocaleProvider.notifier)
                  .set(picked.isEmpty ? null : Locale(picked));
            }
          },
        ),
        FieldRow(
          label: l10n.settingsTheme,
          value: themeMode.label(l10n),
          onTap: () async {
            final picked = await showChoiceSheet(
              context,
              title: l10n.settingsTheme,
              selected: themeMode,
              options: [for (final m in ThemeMode.values) (m, m.label(l10n))],
            );
            if (picked != null) {
              await ref.read(appThemeModeProvider.notifier).set(picked);
            }
          },
        ),
        FieldRow(
          label: l10n.settingsFirstDayOfWeek,
          value: dayLabel(firstDay),
          onTap: () async {
            final picked = await showChoiceSheet(
              context,
              title: l10n.settingsFirstDayOfWeek,
              selected: firstDay,
              options: [
                for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                  (day, dayLabel(day)),
              ],
            );
            if (picked != null) {
              await ref.read(firstDayOfWeekProvider.notifier).set(picked);
            }
          },
        ),
      ],
    );
  }
}

/// [DateTime.monday]…[DateTime.sunday] for the active locale.
int _localeFirstDay(BuildContext context) {
  final index = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  return index == 0 ? DateTime.sunday : index;
}
