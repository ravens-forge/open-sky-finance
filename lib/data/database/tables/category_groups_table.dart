import 'package:drift/drift.dart';

import '../../enums/budget_period.dart';
import '../../enums/category_kind.dart';
import '../../models/category_group.dart';

/// Groups carry the type and the order; the categories inside them carry the
/// look. A group is drawn in the colour of its [CategoryKind], so it has no
/// icon and no colour of its own.
@UseRowClass(CategoryGroupTableRow, generateInsertable: true)
class CategoryGroupsTable extends Table {
  @override
  String get tableName => 'category_groups';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<CategoryKind>()();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// A budget set on the whole group: it covers every category inside it.
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
    // Only spending is budgeted.
    "CHECK (budget_amount IS NULL OR kind = 'expense')",
  ];
}

class CategoryGroupTableRow {
  const CategoryGroupTableRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.isHidden,
    required this.sortOrder,
    required this.budgetAmount,
    required this.budgetPeriod,
    required this.budgetRollover,
  });

  /// The budget is not part of the domain object: it is written only through
  /// `BudgetsRepository`, the way opening balances go through the assets
  /// account.
  factory CategoryGroupTableRow.fromDomain(CategoryGroup g) =>
      CategoryGroupTableRow(
        id: g.id,
        name: g.name,
        kind: g.kind,
        isHidden: g.isHidden,
        sortOrder: g.sortOrder,
        budgetAmount: null,
        budgetPeriod: null,
        budgetRollover: false,
      );

  final String id;
  final String name;
  final CategoryKind kind;
  final bool isHidden;
  final int sortOrder;
  final int? budgetAmount;
  final BudgetPeriod? budgetPeriod;
  final bool budgetRollover;

  CategoryGroup toDomain() => CategoryGroup(
    id: id,
    name: name,
    kind: kind,
    isHidden: isHidden,
    sortOrder: sortOrder,
  );
}
