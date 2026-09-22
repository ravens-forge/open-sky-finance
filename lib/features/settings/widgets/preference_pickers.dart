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

// Language, theme and first day of week: set in Settings and during the
// onboarding, saved as soon as they are picked.

/// The endonym of [locale], or "System (English)" when following the device.
String languageLabel(AppLocalizations l10n, Locale? locale) {
  if (locale != null) return languageEndonyms[locale.languageCode]!;
  // Resolved like MaterialApp does.
  final system = basicLocaleListResolution(
    WidgetsBinding.instance.platformDispatcher.locales,
    AppLocalizations.supportedLocales,
  );
  return l10n.settingsLanguageSystem(languageEndonyms[system.languageCode]!);
}

/// "Monday" for [DateTime.monday], in [l10n]'s language.
String weekdayLabel(AppLocalizations l10n, int day) => capitalizeFirst(
  // 1 January 2024 was a Monday.
  DateFormat.EEEE(l10n.localeName).format(DateTime(2024, 1, day)),
);

/// The chosen first day of week, else the active locale's.
int firstDayOfWeek(BuildContext context, WidgetRef ref) {
  final chosen = ref.watch(firstDayOfWeekProvider).value;
  if (chosen != null) return chosen;
  final index = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  return index == 0 ? DateTime.sunday : index;
}

Future<void> pickLanguage(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final locale = ref.read(userLocaleProvider).value;
  // '' is "System": the sheet returns null when dismissed.
  final picked = await showChoiceSheet(
    context,
    title: l10n.settingsLanguage,
    selected: locale?.languageCode ?? '',
    options: [
      ('', languageLabel(l10n, null)),
      for (final l in AppLocalizations.supportedLocales)
        (l.languageCode, languageLabel(l10n, l)),
    ],
  );
  if (picked != null) {
    await ref
        .read(userLocaleProvider.notifier)
        .set(picked.isEmpty ? null : Locale(picked));
  }
}

Future<void> pickThemeMode(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final picked = await showChoiceSheet(
    context,
    title: l10n.settingsTheme,
    selected: ref.read(appThemeModeProvider).value ?? ThemeMode.system,
    options: [for (final m in ThemeMode.values) (m, m.label(l10n))],
  );
  if (picked != null) {
    await ref.read(appThemeModeProvider.notifier).set(picked);
  }
}

Future<void> pickFirstDayOfWeek(
  BuildContext context,
  WidgetRef ref,
  int selected,
) async {
  final l10n = context.l10n;
  final picked = await showChoiceSheet(
    context,
    title: l10n.settingsFirstDayOfWeek,
    selected: selected,
    options: [
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        (day, weekdayLabel(l10n, day)),
    ],
  );
  if (picked != null) {
    await ref.read(firstDayOfWeekProvider.notifier).set(picked);
  }
}
