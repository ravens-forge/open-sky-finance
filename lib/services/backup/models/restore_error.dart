import 'backup_problem.dart';

/// Why a file cannot be restored. Codes only: the UI words them.
sealed class RestoreError {
  const RestoreError();
}

/// Over the size limit, rejected before reading it.
final class RestoreFileTooLarge extends RestoreError {
  const RestoreFileTooLarge();
}

/// Not JSON, or not an Open Sky Finance backup.
final class RestoreNotABackup extends RestoreError {
  const RestoreNotABackup();
}

/// Made by a newer version of the app, with a format this one cannot read.
final class RestoreNewerVersion extends RestoreError {
  const RestoreNewerVersion();
}

/// A backup, but with problems: every one found, up to a limit.
final class RestoreInvalid extends RestoreError {
  const RestoreInvalid(this.problems, {required this.total});

  final List<BackupProblem> problems;

  /// How many were found, [problems] holding only the first ones.
  final int total;
}

/// Reading the file, the safety backup or the write failed. The data was not
/// changed.
final class RestoreFailed extends RestoreError {
  const RestoreFailed();
}
