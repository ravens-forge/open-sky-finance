import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/repository_data_error.dart';

part 'labels_controller.g.dart';

@Riverpod(keepAlive: true)
class LabelsController extends _$LabelsController {
  @override
  FutureOr<void> build() {}

  /// Creates a label ([id] `null`) or renames one.
  Future<Result<String, RepositoryDataError>> save({
    String? id,
    required String name,
  }) => ref.read(labelsRepositoryProvider).save(id: id, name: name);

  /// How many live transactions carry it, over all time.
  Future<int> uses(String id) async {
    final totals = await ref
        .read(labelsRepositoryProvider)
        .watchTotals(DateTime(1), DateTime(9999))
        .first;
    return totals.where((t) => t.label.id == id).firstOrNull?.count ?? 0;
  }

  /// Its transactions and reminders are kept, without it.
  Future<void> remove(String id) =>
      ref.read(labelsRepositoryProvider).remove(id);
}
