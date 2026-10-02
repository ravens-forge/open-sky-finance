import 'dart:typed_data';

import 'package:open_sky_finance/services/backup/backup_folder_access.dart';
import 'package:open_sky_finance/services/backup/models/backup_folder.dart';
import 'package:open_sky_finance/services/backup/models/backup_folder_unreachable.dart';

/// A granted folder in memory: [files] by name, [reachable] `false` to act
/// like a revoked permission, [picked] what the picker returns.
class FakeBackupFolder implements BackupFolderAccess {
  FakeBackupFolder({this.picked});

  final files = <String, Uint8List>{};
  final released = <String>[];
  var reachable = true;
  BackupFolder? picked;

  void _check() {
    if (!reachable) throw const BackupFolderUnreachable();
  }

  @override
  Future<BackupFolder?> pick() async => picked;

  @override
  Future<void> write(String folder, String name, Uint8List bytes) async {
    _check();
    files[name] = bytes;
  }

  @override
  Future<List<String>> list(String folder) async {
    _check();
    return files.keys.toList();
  }

  @override
  Future<void> delete(String folder, String name) async {
    _check();
    files.remove(name);
  }

  @override
  Future<void> release(String folder) async => released.add(folder);
}
