import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../services/backup/models/backup_problem.dart';
import '../../../services/backup/models/backup_problem_code.dart';
import '../../../services/backup/models/restore_error.dart';

/// How many problems of a rejected file are listed.
const _listed = 5;

String backupProblemLabel(
  AppLocalizations l10n,
  BackupProblem problem,
) => switch (problem.code) {
  BackupProblemCode.missing => l10n.backupProblemMissing(problem.path),
  BackupProblemCode.wrongType => l10n.backupProblemWrongType(problem.path),
  BackupProblemCode.invalidValue => l10n.backupProblemInvalidValue(
    problem.path,
  ),
  BackupProblemCode.duplicateId => l10n.backupProblemDuplicateId(problem.path),
  BackupProblemCode.duplicateName => l10n.backupProblemDuplicateName(
    problem.path,
  ),
  BackupProblemCode.unknownReference => l10n.backupProblemUnknownReference(
    problem.path,
  ),
  BackupProblemCode.brokenRule => l10n.backupProblemBrokenRule(problem.path),
};

/// Why a file was not restored, that the data was not changed, and what to
/// do next.
Future<void> showRestoreErrorDialog(BuildContext context, RestoreError error) {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final (title, body) = switch (error) {
    RestoreFileTooLarge() => (
      l10n.restoreErrorTitle,
      l10n.restoreErrorTooLarge,
    ),
    RestoreNotABackup() => (
      l10n.restoreErrorTitle,
      l10n.restoreErrorNotABackup,
    ),
    RestoreNewerVersion() => (
      l10n.restoreErrorNewerTitle,
      l10n.restoreErrorNewerBody,
    ),
    RestoreInvalid(:final total) => (
      l10n.restoreErrorTitle,
      l10n.restoreErrorInvalid(total),
    ),
    RestoreFailed() => (l10n.restoreFailedTitle, l10n.restoreFailedBody),
  };
  final lines = switch (error) {
    RestoreInvalid(:final problems, :final total) => [
      for (final p in problems.take(_listed)) backupProblemLabel(l10n, p),
      if (total > _listed) l10n.restoreErrorMore(total - _listed),
    ],
    _ => const <String>[],
  };
  return showLedgerDialog<void>(
    context: context,
    kind: DialogKind.error,
    title: title,
    body: body,
    extra: lines.isEmpty
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                Text(
                  line,
                  style: theme.textTheme.bodySmall!.copyWith(height: 1.6),
                ),
            ],
          ),
    actions: [
      Builder(
        builder: (dialog) => TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: Text(l10n.actionClose),
        ),
      ),
    ],
  );
}
