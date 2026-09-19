import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/l10n.dart';
import '../../core/widgets/app_drawer_header.dart';

/// The drawer of the main shell: the pages that are not tabs.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.onHome});

  /// Shows the Home tab.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget item(IconData icon, String label, VoidCallback onTap) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
    Widget page(IconData icon, String label, String path) =>
        item(icon, label, () => context.push(path));

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
            page(Icons.delete_outline, l10n.pageTrash, Routes.trash),
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
