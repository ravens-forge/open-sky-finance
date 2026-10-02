import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'models/backup_folder.dart';
import 'models/backup_folder_unreachable.dart';

part 'backup_folder_access.g.dart';

/// The folder automatic backups go to, through the system (Android Storage
/// Access Framework, iOS security-scoped bookmarks): never a cloud API.
/// Every call but [pick] and [release] throws [BackupFolderUnreachable] when
/// the folder can't be used.
class BackupFolderAccess {
  const BackupFolderAccess();

  static const _channel = MethodChannel('open_sky_finance/backup_folder');

  /// The system folder picker; `null` when cancelled.
  Future<BackupFolder?> pick() => _call(() async {
    final picked = await _channel.invokeMapMethod<String, String>('pick');
    return picked == null
        ? null
        : BackupFolder(ref: picked['ref']!, name: picked['name']!);
  });

  Future<void> write(String folder, String name, Uint8List bytes) => _call(
    () => _channel.invokeMethod<void>('write', {
      'folder': folder,
      'name': name,
      'bytes': bytes,
    }),
  );

  /// Names of the files in [folder].
  Future<List<String>> list(String folder) => _call(
    () async =>
        await _channel.invokeListMethod<String>('list', {'folder': folder}) ??
        const [],
  );

  Future<void> delete(String folder, String name) => _call(
    () =>
        _channel.invokeMethod<void>('delete', {'folder': folder, 'name': name}),
  );

  /// Gives the permission back to the system.
  Future<void> release(String folder) =>
      _channel.invokeMethod<void>('release', {'folder': folder});

  static Future<T> _call<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException {
      throw const BackupFolderUnreachable();
    } on MissingPluginException {
      // A platform without folder access.
      throw const BackupFolderUnreachable();
    }
  }
}

/// Tests override it with a fake folder.
@Riverpod(keepAlive: true)
BackupFolderAccess backupFolderAccess(Ref ref) => const BackupFolderAccess();
