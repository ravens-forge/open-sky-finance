import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../trash/providers/trash_providers.dart';
import 'app_drawer_header.dart';

/// The drawer of the main shell: the pages that are not tabs.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, required this.onHome});

  /// Shows the Home tab.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trashed =
        ref
            .watch(trashProvider)
            .value
            ?.fold(0, (sum, d) => sum + d.transactions.length) ??
        0;
    Widget item(
      IconData icon,
      String label,
      VoidCallback onTap, {
      int badge = 0,
    }) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: badge > 0 ? _Badge(badge) : null,
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
    Widget page(IconData icon, String label, String path, {int badge = 0}) =>
        item(icon, label, () => context.push(path), badge: badge);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const AppDrawerHeader(),
            item(Icons.home_outlined, l10n.pageHome, onHome),
            page(
              Icons.calendar_month_outlined,
              l10n.pageCalendar,
              Routes.calendar,
            ),
            page(
              Icons.account_balance_outlined,
              l10n.pageAssetsAccounts,
              Routes.assetsAccounts,
            ),
            page(
              Icons.category_outlined,
              l10n.pageCategories,
              Routes.categories,
            ),
            page(
              Icons.delete_outline,
              l10n.pageTrash,
              Routes.trash,
              badge: trashed,
            ),
            page(Icons.settings_outlined, l10n.pageSettings, Routes.settings),
            page(Icons.save_outlined, l10n.pageBackups, Routes.backups),
            const Divider(),
            page(Icons.favorite_border, l10n.pageSupport, Routes.support),
          ],
        ),
      ),
    );
  }
}

/// The number of items behind a drawer entry.
class _Badge extends StatelessWidget {
  const _Badge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FinanceColors.of(context).sunken,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          '$count',
          style: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
