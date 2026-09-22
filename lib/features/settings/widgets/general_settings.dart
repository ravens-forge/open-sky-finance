import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/locale.dart';
import '../../../app/main_currency.dart';
import '../../../app/theme_mode.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/currency_picker.dart';
import 'preference_pickers.dart';
import 'settings_row.dart';
import 'settings_section.dart';

/// Main currency, language, theme and first day of week.
class GeneralSettings extends ConsumerWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currency = ref.watch(mainCurrencyProvider).value;
    final themeMode = ref.watch(appThemeModeProvider).value ?? ThemeMode.system;
    final firstDay = firstDayOfWeek(context, ref);
    return SettingsSection(
      title: l10n.settingsGeneral,
      children: [
        SettingsRow(
          icon: Icons.payments_outlined,
          title: l10n.settingsMainCurrency,
          subtitle: currency == null
              ? null
              : l10n.settingsMainCurrencyHint(currency),
          onTap: () async {
            if (currency == null) return;
            final picked = await showCurrencyPicker(context, currency);
            if (picked != null) {
              await ref.read(mainCurrencyProvider.notifier).set(picked);
            }
          },
        ),
        SettingsRow(
          icon: Icons.language,
          title: l10n.settingsLanguage,
          subtitle: languageLabel(l10n, ref.watch(userLocaleProvider).value),
          onTap: () => pickLanguage(context, ref),
        ),
        SettingsRow(
          icon: Icons.dark_mode_outlined,
          title: l10n.settingsTheme,
          subtitle: themeMode.label(l10n),
          onTap: () => pickThemeMode(context, ref),
        ),
        SettingsRow(
          icon: Icons.calendar_today_outlined,
          title: l10n.settingsFirstDayOfWeek,
          subtitle: weekdayLabel(l10n, firstDay),
          onTap: () => pickFirstDayOfWeek(context, ref, firstDay),
        ),
      ],
    );
  }
}
