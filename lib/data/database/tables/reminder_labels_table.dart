import 'package:drift/drift.dart';

import 'labels_table.dart';
import 'reminders_table.dart';

@DataClassName('ReminderLabelTableRow')
class ReminderLabelsTable extends Table {
  @override
  String get tableName => 'reminder_labels';

  TextColumn get reminderId =>
      text().references(RemindersTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get labelId =>
      text().references(LabelsTable, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {reminderId, labelId};
}
