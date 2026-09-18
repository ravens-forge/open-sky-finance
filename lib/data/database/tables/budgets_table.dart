import 'package:drift/drift.dart';

import '../../enums/budget_period.dart';
import '../../models/budget.dart';
import 'categories_table.dart';

@UseRowClass(BudgetTableRow, generateInsertable: true)
class BudgetsTable extends Table {
  @override
  String get tableName => 'budgets';

  TextColumn get id => text()();
  TextColumn get categoryId => text().unique().references(
    CategoriesTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get amount => integer()();
  TextColumn get period => textEnum<BudgetPeriod>()();
  BoolColumn get rollover => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (amount > 0)'];
}

class BudgetTableRow {
  const BudgetTableRow({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.rollover,
  });

  factory BudgetTableRow.fromDomain(Budget b) => BudgetTableRow(
    id: b.id,
    categoryId: b.categoryId,
    amount: b.amount,
    period: b.period,
    rollover: b.rollover,
  );

  final String id;
  final String categoryId;
  final int amount;
  final BudgetPeriod period;
  final bool rollover;

  Budget toDomain() => Budget(
    id: id,
    categoryId: categoryId,
    amount: amount,
    period: period,
    rollover: rollover,
  );
}
