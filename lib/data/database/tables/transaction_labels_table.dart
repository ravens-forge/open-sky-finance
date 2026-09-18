import 'package:drift/drift.dart';

import 'labels_table.dart';
import 'transactions_table.dart';

@DataClassName('TransactionLabelTableRow')
class TransactionLabelsTable extends Table {
  @override
  String get tableName => 'transaction_labels';

  TextColumn get transactionId =>
      text().references(TransactionsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get labelId =>
      text().references(LabelsTable, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {transactionId, labelId};
}
