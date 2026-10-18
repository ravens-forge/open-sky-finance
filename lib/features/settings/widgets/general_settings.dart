import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/locale.dart';
import '../../../app/default_currency.dart';
import '../../../app/theme_mode.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/currency_picker.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../data/providers.dart';
import 'preference_pickers.dart';
import 'settings_row.dart';
import 'settings_section.dart';

/// Default currency, language, theme and first day of week.
class GeneralSettings extends ConsumerWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currency = ref.watch(defaultCurrencyProvider).value;
    final themeMode = ref.watch(appThemeModeProvider).value ?? ThemeMode.system;
    final firstDay = firstDayOfWeek(context, ref);
    return SettingsSection(
      title: l10n.settingsGeneral,
      children: [
        SettingsRow(
          icon: Icons.payments_outlined,
          title: l10n.settingsDefaultCurrency,
          subtitle: currency == null
              ? null
              : l10n.settingsDefaultCurrencyHint(currency),
          onTap: () async {
            if (currency == null) return;
            final picked = await showCurrencyPicker(context, currency);
            if (picked == null || picked == currency || !context.mounted) {
              return;
            }
            if (!await _confirmBudgets(context, ref, picked)) return;
            await ref.read(defaultCurrencyProvider.notifier).set(picked);
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

/// Budgets are in the default currency: with any, asks before they move to
/// [picked]. Their amounts stay; nothing is converted.
Future<bool> _confirmBudgets(
  BuildContext context,
  WidgetRef ref,
  String picked,
) async {
  final budgets = await ref.read(budgetsRepositoryProvider).watchAll().first;
  if (budgets.isEmpty) return true;
  if (!context.mounted) return false;
  final l10n = context.l10n;
  final confirmed = await showLedgerDialog<bool>(
    context: context,
    title: l10n.defaultCurrencyChangeTitle(picked),
    body: l10n.defaultCurrencyChangeBody(budgets.length, picked),
    actions: [
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
      ),
      Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.defaultCurrencyChangeUse(picked)),
        ),
      ),
    ],
  );
  return confirmed ?? false;
}
