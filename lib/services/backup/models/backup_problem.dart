import 'package:flutter/foundation.dart';

import 'backup_problem_code.dart';

@immutable
class BackupProblem {
  const BackupProblem(this.code, this.path);

  final BackupProblemCode code;

  /// Where it is, e.g. `data.transactions[12].amount`: field names and
  /// positions only, never a value from the file.
  final String path;

  @override
  bool operator ==(Object other) =>
      other is BackupProblem && other.code == code && other.path == path;

  @override
  int get hashCode => Object.hash(code, path);

  @override
  String toString() => '${code.name} at $path';
}
