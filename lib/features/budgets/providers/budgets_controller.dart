import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/repository_data_error.dart';

part 'budgets_controller.g.dart';

/// Writes of Edit budgets. The Budget page updates through its streams.
@Riverpod(keepAlive: true)
class BudgetsController extends _$BudgetsController {
  @override
  FutureOr<void> build() {}

  /// Sets each budget of [changes] (group or category id to micro-units) and
  /// clears the ones mapped to `null`, all at once.
  Future<Result<void, RepositoryDataError>> save(Map<String, int?> changes) =>
      ref.read(budgetsRepositoryProvider).setAll(changes);
}
