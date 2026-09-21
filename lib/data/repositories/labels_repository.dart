import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/result.dart';
import '../database/app_database.dart';
import '../database/tables/labels_table.dart';
import '../database/tables/transaction_labels_table.dart';
import '../database/tables/transactions_table.dart';
import '../models/label.dart';
import 'repository_data_error.dart';
import 'report_sql.dart';
import 'valid_name.dart';
import '../models/label_total.dart';

part 'labels_repository.g.dart';

@DriftAccessor(tables: [LabelsTable, TransactionLabelsTable, TransactionsTable])
class LabelsRepository extends DatabaseAccessor<AppDatabase>
    with _$LabelsRepositoryMixin {
  LabelsRepository(super.attachedDatabase);

  SimpleSelectStatement<$LabelsTableTable, LabelTableRow> _byName() =>
      select(labelsTable)..orderBy([(l) => OrderingTerm(expression: l.name)]);

  Stream<List<Label>> watchAll() => _byName().map((r) => r.toDomain()).watch();

  /// Creates a label ([id] `null`) or renames one. Names are unique ignoring
  /// case, accents included (`Été` = `été`). Returns the id.
  Future<Result<String, RepositoryDataError>> save({
    String? id,
    required String name,
  }) => transaction(() async {
    final valid = validName(name);
    if (valid == null) return const Err(RepositoryDataError.invalidName);
    final lower = valid.toLowerCase();
    final labels = await _byName().get();
    if (labels.any((l) => l.id != id && l.name.toLowerCase() == lower)) {
      return const Err(RepositoryDataError.duplicateName);
    }

    if (id == null) {
      final newLabelId = newId();
      await into(labelsTable)
          .insert(LabelsTableCompanion.insert(id: newLabelId, name: valid));
      return Ok(newLabelId);
    }
    final updated = await (update(labelsTable)..where((l) => l.id.equals(id)))
        .write(LabelsTableCompanion(name: Value(valid)));
    return updated == 0 ? const Err(RepositoryDataError.notFound) : Ok(id);
  });

  /// Removes the label from its transactions and reminders (cascade).
  Future<void> remove(String id) =>
      (delete(labelsTable)..where((l) => l.id.equals(id))).go();

  /// Labels of the live transactions in [from, to), by transaction id, each
  /// list by name. Transactions without labels are left out.
  Stream<Map<String, List<Label>>> watchByTransaction(
    DateTime from,
    DateTime to,
  ) =>
      customSelect(
        '''
SELECT tl.transaction_id AS transaction_id, l.* FROM transaction_labels tl
JOIN labels l ON l.id = tl.label_id
JOIN transactions t ON t.id = tl.transaction_id
WHERE t.deleted_at IS NULL AND t.occurred_at >= ?1 AND t.occurred_at < ?2
ORDER BY l.name''',
        variables: [wallClockVariable(from), wallClockVariable(to)],
        readsFrom: {labelsTable, transactionLabelsTable, transactionsTable},
      ).watch().map((rows) {
        final byTransaction = <String, List<Label>>{};
        for (final r in rows) {
          (byTransaction[r.read<String>('transaction_id')] ??= []).add(
            labelsTable.map(r.data).toDomain(),
          );
        }
        return byTransaction;
      });

  /// Every label, by name, with the count and signed total (transfers count but
  /// add nothing) of its live transactions in [from, to).
  Stream<List<LabelTotal>> watchTotals(DateTime from, DateTime to) =>
      customSelect(
        '''
SELECT l.*, t.currency AS total_currency, COUNT(t.id) AS count,
  SUM(CASE WHEN t.type = 'transfer' THEN 0 ELSE t.amount END) AS total
FROM labels l
LEFT JOIN transaction_labels tl ON tl.label_id = l.id
LEFT JOIN transactions t ON t.id = tl.transaction_id AND t.deleted_at IS NULL
  AND t.occurred_at >= ?1 AND t.occurred_at < ?2
GROUP BY l.id, t.currency
ORDER BY l.name''',
        variables: [wallClockVariable(from), wallClockVariable(to)],
        readsFrom: {labelsTable, transactionLabelsTable, transactionsTable},
      ).watch().map((rows) {
        final labels = <String, Label>{};
        final counts = <String, int>{};
        final totals = <String, Map<String, int>>{};
        for (final r in rows) {
          final label = labelsTable.map(r.data).toDomain();
          labels[label.id] = label;
          counts[label.id] = (counts[label.id] ?? 0) + r.read<int>('count');
          final total = totals[label.id] ??= {};
          final currency = r.readNullable<String>('total_currency');
          if (currency != null) total[currency] = r.read<int>('total');
        }
        return [
          for (final id in labels.keys)
            LabelTotal(
              label: labels[id]!,
              count: counts[id]!,
              total: totals[id]!,
            ),
        ];
      });
}
