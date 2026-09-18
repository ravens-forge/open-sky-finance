import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/settings_table.dart';
import '../models/home_section.dart';
import '../database/tables/setting_keys.dart';

part 'settings_repository.g.dart';

@DriftAccessor(tables: [SettingsTable])
class SettingsRepository extends DatabaseAccessor<AppDatabase>
    with _$SettingsRepositoryMixin {
  SettingsRepository(super.attachedDatabase);

  SimpleSelectStatement<$SettingsTableTable, SettingTableRow> _byKey(
    String key,
  ) => select(settingsTable)..where((s) => s.key.equals(key));

  Stream<String?> watch(String key) =>
      _byKey(key).map((s) => s.value).watchSingleOrNull();

  Future<String?> get(String key) =>
      _byKey(key).map((s) => s.value).getSingleOrNull();

  /// `null` removes the setting (back to its default).
  Future<void> set(String key, String? value) => value == null
      ? (delete(settingsTable)..where((s) => s.key.equals(key))).go()
      : into(settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: key, value: value),
        );

  Stream<List<HomeSection>> watchHomeSections() =>
      watch(SettingKeys.homeSections).map(HomeSection.listFromJson);

  Future<void> setHomeSections(List<HomeSection> sections) =>
      set(SettingKeys.homeSections, HomeSection.listToJson(sections));
}
