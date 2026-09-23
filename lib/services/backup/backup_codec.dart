import 'dart:convert';
import 'dart:typed_data';

import '../../core/dates/wall_clock.dart';
import '../../core/result.dart';
import '../../data/models/app_snapshot.dart';
import '../../data/models/home_section.dart';
import '../../data/repositories/setting_keys.dart';
import 'backup_reader.dart';
import 'json_fields.dart';
import 'migrations/backup_upgraders.dart';
import 'models/backup_problem_code.dart';
import 'models/restore_error.dart';

/// [AppSnapshot] ⇄ the backup JSON. Pure Dart, so it runs in a background
/// isolate.
abstract final class BackupCodec {
  static const format = 'open-sky-finance-backup';

  /// UTF-8 JSON with 2-space indentation.
  static Uint8List encode(AppSnapshot snapshot) => utf8.encode(
    const JsonEncoder.withIndent('  ').convert(_toJson(snapshot)),
  );

  /// Parses, upgrades and checks a whole file, collecting every problem
  /// before failing.
  static Result<AppSnapshot, RestoreError> decode(List<int> bytes) {
    final Object? json;
    try {
      // A byte order mark is not ours, but harmless.
      final text = utf8.decode(bytes);
      json = jsonDecode(text.startsWith('\uFEFF') ? text.substring(1) : text);
    } on FormatException {
      return const Err(RestoreNotABackup());
    }
    if (json is! Map<String, Object?> || json['format'] != format) {
      return const Err(RestoreNotABackup());
    }
    final problems = ProblemCollector();
    final version = json['schemaVersion'];
    if (version is! int || version < 1) {
      problems.add(
        version == null
            ? BackupProblemCode.missing
            : BackupProblemCode.invalidValue,
        'schemaVersion',
      );
      return Err(RestoreInvalid(problems.problems, total: problems.total));
    }
    if (version > currentSchemaVersion) {
      return const Err(RestoreNewerVersion());
    }
    final snapshot = readBackup(
      JsonFields(upgradeBackup(json, version), '', problems),
      problems,
    );
    return problems.isEmpty
        ? Ok(snapshot)
        : Err(RestoreInvalid(problems.problems, total: problems.total));
  }

  static Map<String, Object?> _toJson(AppSnapshot s) {
    String instant(DateTime at) => at.toUtc().toIso8601String();
    String? nullableInstant(DateTime? at) => at == null ? null : instant(at);
    String? nullableWallClock(DateTime? at) =>
        at == null ? null : formatWallClock(at);
    Map<String, Object?>? budget(int? amount, String? period, bool rollover) =>
        amount == null
        ? null
        : {'amount': amount, 'period': period, 'rollover': rollover};

    final reminderLabels = <String, List<String>>{};
    for (final r in s.reminderLabels) {
      (reminderLabels[r.reminderId] ??= []).add(r.labelId);
    }
    final transactionLabels = <String, List<String>>{};
    for (final t in s.transactionLabels) {
      (transactionLabels[t.transactionId] ??= []).add(t.labelId);
    }
    final settings = s.settings;

    return {
      'format': format,
      'schemaVersion': currentSchemaVersion,
      'appVersion': s.appVersion,
      'exportedAt': instant(s.exportedAt),
      'data': {
        'settings': {
          'mainCurrency': settings[SettingKeys.mainCurrency],
          'themeMode': settings[SettingKeys.themeMode] ?? 'system',
          'locale': settings[SettingKeys.locale],
          'firstDayOfWeek': int.tryParse(
            settings[SettingKeys.firstDayOfWeek] ?? '',
          ),
          'homeSections': [
            for (final section in HomeSection.listFromJson(
              settings[SettingKeys.homeSections],
            ))
              {'id': section.id.name, 'visible': section.visible},
          ],
        },
        'assetsAccounts': [
          for (final a in s.assetsAccounts)
            {
              'id': a.id,
              'name': a.name,
              'type': a.type.name,
              'currency': a.currency,
              'isHidden': a.isHidden,
              'isFavorite': a.isFavorite,
              'excludeFromNetWorth': a.excludeFromNetWorth,
              'creditLimit': a.creditLimit,
              'sortOrder': a.sortOrder,
              'notes': a.notes,
              'createdAt': instant(a.createdAt),
              'updatedAt': instant(a.updatedAt),
            },
        ],
        'categoryGroups': [
          for (final g in s.categoryGroups)
            {
              'id': g.id,
              'name': g.name,
              'kind': g.kind.name,
              'isHidden': g.isHidden,
              'sortOrder': g.sortOrder,
              'budget': budget(
                g.budgetAmount,
                g.budgetPeriod?.name,
                g.budgetRollover,
              ),
            },
        ],
        'categories': [
          for (final c in s.categories)
            {
              'id': c.id,
              'name': c.name,
              'groupId': c.groupId,
              'icon': c.icon,
              'color': c.color,
              'isHidden': c.isHidden,
              'sortOrder': c.sortOrder,
              'budget': budget(
                c.budgetAmount,
                c.budgetPeriod?.name,
                c.budgetRollover,
              ),
            },
        ],
        'labels': [
          for (final l in s.labels) {'id': l.id, 'name': l.name},
        ],
        'reminders': [
          for (final r in s.reminders)
            {
              'id': r.id,
              'type': r.type.name,
              'title': r.title,
              'amount': r.amount,
              'assetsAccountId': r.assetsAccountId,
              'toAssetsAccountId': r.toAssetsAccountId,
              'toAmount': r.toAmount,
              'categoryId': r.categoryId,
              'currency': r.currency,
              'notes': r.notes,
              'labelIds': reminderLabels[r.id] ?? const <String>[],
              'frequency': r.frequency.name,
              'interval': r.interval,
              'startDate': formatWallClock(r.startDate),
              'nextDueAt': nullableWallClock(r.nextDueAt),
              'endDate': nullableWallClock(r.endDate),
              'remainingOccurrences': r.remainingOccurrences,
              'autoPost': r.autoPost,
              'notify': r.notify,
              'isPaused': r.isPaused,
              'sortOrder': r.sortOrder,
              'createdAt': instant(r.createdAt),
              'updatedAt': instant(r.updatedAt),
            },
        ],
        'transactions': [
          for (final t in s.transactions)
            {
              'id': t.id,
              'type': t.type.name,
              'occurredAt': formatWallClock(t.occurredAt),
              'title': t.title,
              'amount': t.amount,
              'assetsAccountId': t.assetsAccountId,
              'toAssetsAccountId': t.toAssetsAccountId,
              'toAmount': t.toAmount,
              'categoryId': t.categoryId,
              'currency': t.currency,
              'exchangeRate': t.exchangeRate,
              'notes': t.notes,
              'labelIds': transactionLabels[t.id] ?? const <String>[],
              'reminderId': t.reminderId,
              'deletedAt': nullableInstant(t.deletedAt),
              'createdAt': instant(t.createdAt),
              'updatedAt': instant(t.updatedAt),
            },
        ],
      },
    };
  }
}
