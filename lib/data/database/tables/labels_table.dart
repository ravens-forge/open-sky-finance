import 'package:drift/drift.dart';

import '../../models/label.dart';

@UseRowClass(LabelTableRow, generateInsertable: true)
class LabelsTable extends Table {
  @override
  String get tableName => 'labels';

  TextColumn get id => text()();

  /// Unique ignoring ASCII case in SQL; the repository also compares
  /// accented letters.
  TextColumn get name => text().customConstraint(
    'NOT NULL UNIQUE COLLATE NOCASE CHECK (length(name) BETWEEN 1 AND 100)',
  )();

  @override
  Set<Column> get primaryKey => {id};
}

class LabelTableRow {
  const LabelTableRow({required this.id, required this.name});

  factory LabelTableRow.fromDomain(Label l) =>
      LabelTableRow(id: l.id, name: l.name);

  final String id;
  final String name;

  Label toDomain() => Label(id: id, name: name);
}
