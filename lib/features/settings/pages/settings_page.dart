import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../data/models/home_section.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../data_management/providers/last_backup_provider.dart';
import '../../data_management/widgets/erase_all_data_flow.dart';
import '../../data_management/widgets/last_backup_label.dart';
import '../../home/providers/home_providers.dart';
import '../../home/widgets/favorite_accounts_sheet.dart';
import '../../trash/providers/trash_providers.dart';
import '../widgets/about_settings.dart';
import '../widgets/general_settings.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final favorites =
        ref.watch(assetsAccountsProvider).value?.where((a) => a.isFavorite) ??
        const [];
    final shown = [
      for (final s
          in ref.watch(homeSectionsProvider).value ?? const <HomeSection>[])
        if (s.visible) s.id.label(l10n),
    ];
    final trashed =
        ref
            .watch(trashProvider)
            .value
            ?.fold(0, (sum, d) => sum + d.transactions.length) ??
        0;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pageSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          const GeneralSettings(),
          SettingsSection(
            title: l10n.pageHome,
            children: [
              SettingsRow(
                icon: Icons.star_border,
                title: l10n.homeSectionFavoriteAccounts,
                subtitle: l10n.settingsFavoriteAccountsHint(favorites.length),
                onTap: () => showFavoriteAccountsSheet(context),
              ),
              SettingsRow(
                icon: Icons.drag_indicator,
                title: l10n.settingsHomeSections,
                subtitle: shown.isEmpty
                    ? l10n.settingsHomeSectionsNone
                    : shown.join(', '),
                onTap: () => context.push(Routes.homeSections),
              ),
            ],
          ),
          SettingsSection(
            title: l10n.settingsManage,
            children: [
              SettingsRow(
                icon: Icons.grid_view,
                title: l10n.pageCategories,
                onTap: () => context.push(Routes.categories),
              ),
              // Main pages: shown as their tab.
              SettingsRow(
                icon: Icons.sell_outlined,
                title: l10n.pageLabels,
                onTap: () => context.go(Routes.labels),
              ),
              SettingsRow(
                icon: Icons.pie_chart_outline,
                title: l10n.pageBudgets,
                onTap: () => context.go(Routes.budgets),
              ),
              SettingsRow(
                icon: Icons.notifications_none,
                title: l10n.pageReminders,
                onTap: () => context.go(Routes.reminders),
              ),
              SettingsRow(
                icon: Icons.delete_outline,
                title: l10n.pageTrash,
                subtitle: l10n.settingsTrashCount(trashed),
                onTap: () => context.push(Routes.trash),
              ),
            ],
          ),
          SettingsSection(
            title: l10n.settingsData,
            children: [
              SettingsRow(
                icon: Icons.cloud_outlined,
                title: l10n.pageBackups,
                subtitle: lastBackupLabel(
                  l10n,
                  ref.watch(lastBackupProvider).value,
                ),
                onTap: () => context.push(Routes.backups),
              ),
              SettingsRow(
                icon: Icons.delete_outline,
                title: l10n.settingsEraseAll,
                subtitle: l10n.settingsEraseAllHint,
                color: FinanceColors.of(context).expense,
                onTap: () => eraseAllData(context, ref),
              ),
            ],
          ),
          const AboutSettings(),
        ],
      ),
    );
  }
}
