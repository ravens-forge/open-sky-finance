/// Upgraders between backup format versions, oldest first: the one at index
/// `n - 1` turns a version `n` file into version `n + 1`. Every
/// `schemaVersion` bump adds one (in its own `v{n}_to_v{n+1}.dart`), so any
/// old backup can still be restored.
const List<Map<String, Object?> Function(Map<String, Object?> json)>
backupUpgraders = [];

/// The version exports write, and the newest restores accept.
final currentSchemaVersion = 1 + backupUpgraders.length;

/// Runs the upgraders from [version] up to [currentSchemaVersion] in order.
Map<String, Object?> upgradeBackup(Map<String, Object?> json, int version) {
  for (var i = version - 1; i < backupUpgraders.length; i++) {
    json = backupUpgraders[i](json);
  }
  return json;
}
