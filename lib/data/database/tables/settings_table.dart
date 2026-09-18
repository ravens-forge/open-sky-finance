import 'package:drift/drift.dart';

@DataClassName('SettingTableRow')
class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();

  /// Plain string or JSON.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
