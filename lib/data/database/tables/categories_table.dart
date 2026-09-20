import 'package:drift/drift.dart';

import '../../enums/budget_period.dart';
import '../../models/category.dart';
import 'category_groups_table.dart';

@UseRowClass(CategoryTableRow, generateInsertable: true)
@TableIndex(name: 'categories_group_id', columns: {#groupId})
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get groupId => text().references(
    CategoryGroupsTable,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// Material icon key in snake_case.
  TextColumn get icon => text()();

  /// ARGB.
  IntColumn get color => integer()();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  IntColumn get budgetAmount => integer().nullable()();
  TextColumn get budgetPeriod => textEnum<BudgetPeriod>().nullable()();
  BoolColumn get budgetRollover =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) BETWEEN 1 AND 100)',
    'CHECK ((budget_amount IS NULL) = (budget_period IS NULL))',
    'CHECK (budget_amount IS NULL OR budget_amount > 0)',
  ];
}

class CategoryTableRow {
  const CategoryTableRow({
    required this.id,
    required this.name,
    required this.groupId,
    required this.icon,
    required this.color,
    required this.isHidden,
    required this.sortOrder,
    required this.budgetAmount,
    required this.budgetPeriod,
    required this.budgetRollover,
  });

  /// As for a group, the budget is written only through `BudgetsRepository`.
  factory CategoryTableRow.fromDomain(Category c) => CategoryTableRow(
    id: c.id,
    name: c.name,
    groupId: c.groupId,
    icon: c.icon,
    color: c.color,
    isHidden: c.isHidden,
    sortOrder: c.sortOrder,
    budgetAmount: null,
    budgetPeriod: null,
    budgetRollover: false,
  );

  final String id;
  final String name;
  final String groupId;
  final String icon;
  final int color;
  final bool isHidden;
  final int sortOrder;
  final int? budgetAmount;
  final BudgetPeriod? budgetPeriod;
  final bool budgetRollover;

  Category toDomain() => Category(
    id: id,
    name: name,
    groupId: groupId,
    icon: icon,
    color: color,
    isHidden: isHidden,
    sortOrder: sortOrder,
  );
}
