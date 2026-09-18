import 'package:drift/drift.dart';

import '../../enums/category_kind.dart';
import '../../models/category.dart';

@UseRowClass(CategoryTableRow, generateInsertable: true)
@TableIndex(name: 'categories_parent_id', columns: {#parentId})
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<CategoryKind>()();
  TextColumn get parentId => text().nullable().references(
    CategoriesTable,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get icon => text()();
  IntColumn get color => integer().nullable()();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) BETWEEN 1 AND 100)',
    'CHECK (parent_id IS NOT NULL OR color IS NOT NULL)',
    'CHECK (parent_id IS NULL OR parent_id <> id)',
  ];
}

class CategoryTableRow {
  const CategoryTableRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.parentId,
    required this.icon,
    required this.color,
    required this.isHidden,
    required this.sortOrder,
  });

  factory CategoryTableRow.fromDomain(Category c) => CategoryTableRow(
    id: c.id,
    name: c.name,
    kind: c.kind,
    parentId: c.parentId,
    icon: c.icon,
    color: c.color,
    isHidden: c.isHidden,
    sortOrder: c.sortOrder,
  );

  final String id;
  final String name;
  final CategoryKind kind;
  final String? parentId;
  final String icon;
  final int? color;
  final bool isHidden;
  final int sortOrder;

  Category toDomain() => Category(
    id: id,
    name: name,
    kind: kind,
    parentId: parentId,
    icon: icon,
    color: color,
    isHidden: isHidden,
    sortOrder: sortOrder,
  );
}
