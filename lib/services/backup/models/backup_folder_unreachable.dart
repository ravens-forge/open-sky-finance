/// The granted folder can't be used any more: its permission was removed,
/// or the app that provides it is gone.
class BackupFolderUnreachable implements Exception {
  const BackupFolderUnreachable();
}
