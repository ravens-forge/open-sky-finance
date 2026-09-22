@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/services/backup/backup_folders.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

Future<void> _settings(
  WidgetTester tester,
  ProviderContainer container,
  AppLocalizations l10n,
) async {
  container.read(routerProvider).go(Routes.settings);
  await settle(tester);
}

/// Settings with the first erase dialog open, and the second one checked
/// when [stepTwo].
Future<void> Function(WidgetTester, ProviderContainer, AppLocalizations)
_erase({bool stepTwo = false}) => (tester, container, l10n) async {
  await _settings(tester, container, l10n);
  await scrollTo(tester, find.text(l10n.settingsEraseAll));
  await tester.ensureVisible(find.text(l10n.settingsEraseAll));
  await settle(tester);
  await tester.tap(find.text(l10n.settingsEraseAll));
  await settle(tester);
  if (stepTwo) {
    await tester.tap(find.text(l10n.actionContinue));
    await settle(tester);
    await tester.tap(find.byType(Checkbox));
    await settle(tester);
  }
};

/// Demo data backed up on Thursday, September 10, 2026.
Future<void> _seed(AppDatabase db) async {
  await seedDemo(db);
  await db.settingsRepository.set(
    SettingKeys.lastBackupAt,
    DateTime(2026, 9, 10, 8).toUtc().toIso8601String(),
  );
}

void main() {
  setUpAll(
    () => PackageInfo.setMockInitialValues(
      appName: 'Open Sky Finance',
      packageName: 'com.ravensforge.open_sky_finance',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    ),
  );

  appGolden(
    'settings',
    height: 1390,
    showHome: true,
    seed: _seed,
    act: _settings,
  );

  appGolden('erase_data_step_1', seed: _seed, act: _erase());

  appGolden('erase_data_step_2', seed: _seed, act: _erase(stepTwo: true));

  appGolden(
    'erase_data_done',
    seed: _seed,
    overrides: [backupCopyFoldersProvider.overrideWith((_) => [])],
    act: (tester, container, l10n) async {
      await _erase(stepTwo: true)(tester, container, l10n);
      await tester.tap(find.text(l10n.eraseAction));
      await settle(tester);
      await settle(tester);
    },
  );
}
