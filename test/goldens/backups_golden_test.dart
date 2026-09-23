@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/features/data_management/models/restore_preview.dart';
import 'package:open_sky_finance/features/data_management/pages/restore_preview_page.dart';
import 'package:open_sky_finance/features/data_management/widgets/restore_error_dialog.dart';
import 'package:open_sky_finance/services/backup/backup_codec.dart';
import 'package:open_sky_finance/services/backup/models/backup_problem.dart';
import 'package:open_sky_finance/services/backup/models/backup_problem_code.dart';
import 'package:open_sky_finance/services/backup/models/loaded_backup.dart';
import 'package:open_sky_finance/services/backup/models/restore_error.dart';

import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

/// Demo data saved to a file this morning.
Future<void> _seed(AppDatabase db) async {
  await seedDemo(db);
  await db.settingsRepository.set(
    SettingKeys.lastBackupAt,
    DateTime(2026, 9, 17, 9, 12).toUtc().toIso8601String(),
  );
  await db.settingsRepository.set(SettingKeys.lastBackupDestination, 'saved');
  await db.settingsRepository.set(SettingKeys.lastBackupSize, '219136');
}

NavigatorState _navigator(ProviderContainer container) =>
    container.read(routerProvider).routerDelegate.navigatorKey.currentState!;

void main() {
  appGolden(
    'backups',
    seed: _seed,
    act: (tester, container, l10n) async {
      unawaited(container.read(routerProvider).push(Routes.backups));
      await settle(tester);
    },
  );

  appGolden(
    'backups_none',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      unawaited(container.read(routerProvider).push(Routes.backups));
      await settle(tester);
    },
  );

  appGolden(
    'restore_backup_preview',
    height: 1000,
    seed: _seed,
    act: (tester, container, l10n) async {
      final snapshot = switch (BackupCodec.decode(
        File('test/fixtures/backup/v1_sample.json').readAsBytesSync(),
      )) {
        Ok(:final value) => value,
        Err() => throw StateError('fixture'),
      };
      final current = await tester.runAsync(
        () => container
            .read(appDatabaseProvider)
            .backupRepository
            .currentData(snapshot.exportedAt, before: DateTime(2026, 9, 18)),
      );
      _navigator(container).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => RestorePreviewPage(
            preview: RestorePreview(
              backup: LoadedBackup(
                fileName: 'open-sky-finance-backup-20260910-211400.json',
                size: 1153434,
                snapshot: snapshot,
              ),
              current: current!,
            ),
          ),
        ),
      );
      await settle(tester);
    },
  );

  appGolden(
    'restore_backup_error',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      unawaited(container.read(routerProvider).push(Routes.backups));
      await settle(tester);
      unawaited(
        showRestoreErrorDialog(
          _navigator(container).context,
          RestoreInvalid([
            for (final (code, path) in [
              (BackupProblemCode.missing, 'data.transactions[3].amount'),
              (
                BackupProblemCode.unknownReference,
                'data.categories[2].groupId',
              ),
              (BackupProblemCode.brokenRule, 'data.transactions[5].toAmount'),
              (BackupProblemCode.duplicateName, 'data.labels[1].name'),
              (BackupProblemCode.invalidValue, 'data.reminders[0].interval'),
              (BackupProblemCode.wrongType, 'data.settings.firstDayOfWeek'),
            ])
              BackupProblem(code, path),
          ], total: 8),
        ),
      );
      await settle(tester);
    },
  );
}
