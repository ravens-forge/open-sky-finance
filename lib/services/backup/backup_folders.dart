import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_folders.g.dart';

/// Private folders holding copies of the user's data outside the database:
/// safety backups made before a restore or import, files written for the
/// share sheet, and the copy of a Bluecoins file being imported. Tests
/// override it with temporary folders.
@Riverpod(keepAlive: true)
Future<List<Directory>> backupCopyFolders(Ref ref) async {
  final support = await getApplicationSupportDirectory();
  final cache = await getTemporaryDirectory();
  return [
    Directory('${support.path}${Platform.pathSeparator}safety_backups'),
    Directory('${cache.path}${Platform.pathSeparator}share'),
    Directory('${cache.path}${Platform.pathSeparator}bluecoins_import'),
  ];
}
