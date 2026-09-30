import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/features/feedback/providers/technical_info_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../goldens/demo_data.dart';
import '../pump_app.dart';

/// Every screen with sample data; ids come from [demo] once it is seeded.
final _screens = <String, String Function()>{
  'home': () => Routes.home,
  'transactions': () => Routes.transactions,
  'reminders': () => Routes.reminders,
  'reminder': () => Routes.reminder(demo['reminder:Rent']!),
  'new reminder': () => Routes.newReminder,
  'balance sheet': () => Routes.balanceSheet,
  'budget': () => Routes.budgets,
  'edit budgets': () => Routes.editBudgets,
  'net income': () => Routes.netIncome,
  'labels': () => Routes.labels,
  'assets accounts': () => Routes.assetsAccounts,
  'assets account': () => Routes.assetsAccount(demo['Visa']!),
  'assets account editor': () => Routes.editAssetsAccount(demo['Visa']!),
  'categories': () => Routes.categories,
  'category editor': () => Routes.category(demo['Groceries']!),
  'new category group': () => Routes.newCategoryGroup(CategoryKind.expense),
  'transaction editor': () => Routes.transaction(demo['tx:Central Market']!),
  'new transaction': () => Routes.newTransaction(),
  'trash': () => Routes.trash,
  'settings': () => Routes.settings,
  'arrange home': () => Routes.homeSections,
  'backups': () => Routes.backups,
  'report a bug': () => Routes.reportBug,
  'support': () => Routes.support,
};

void main() {
  setUpAll(
    () => PackageInfo.setMockInitialValues(
      appName: 'Open Sky Finance',
      packageName: 'com.ravensforge.open_sky_finance',
      version: '1.0.0',
      buildNumber: '42',
      buildSignature: '',
    ),
  );

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    for (final MapEntry(key: name, value: route) in _screens.entries) {
      testWidgets('$name (${theme.name}): 48 px targets, labels, contrast', (
        tester,
      ) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        final container = await pumpApp(
          tester,
          showHome: true,
          overrides: [
            osVersionProvider.overrideWith((_) async => 'Android 15'),
          ],
          seed: (db) async {
            await seedDemo(db);
            await db.settingsRepository.set(SettingKeys.themeMode, theme.name);
          },
        );
        container.read(routerProvider).go(route());
        await settle(tester);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    }
  }
}
