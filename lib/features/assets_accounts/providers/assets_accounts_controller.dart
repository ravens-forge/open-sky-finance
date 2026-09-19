import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result.dart';
import '../../../data/models/assets_account_draft.dart';
import '../../../data/models/assets_account_usage.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/assets_accounts_repository.dart';
import '../../../data/repositories/repository_data_error.dart';
import '../models/reorder_ids.dart';

part 'assets_accounts_controller.g.dart';

/// Writes of the Assets accounts screens. Lists update through their streams.
@Riverpod(keepAlive: true)
class AssetsAccountsController extends _$AssetsAccountsController {
  @override
  FutureOr<void> build() {}

  AssetsAccountsRepository get _repository =>
      ref.read(assetsAccountsRepositoryProvider);

  Future<Result<String, RepositoryDataError>> save(AssetsAccountDraft draft) =>
      _repository.save(draft);

  Future<void> setFavorite(String id, bool isFavorite) =>
      _repository.setFavorite(id, isFavorite);

  Future<void> hide(String id) => _repository.setHidden(id, true);

  /// Moves [group]'s item at [from] to [to] within [all] (every id, in order).
  Future<void> move(List<String> all, List<String> group, int from, int to) =>
      _repository.reorder(reorderIds(all, group, from, to));

  Future<AssetsAccountUsage> usage(String id) => _repository.usage(id);

  /// Permanently, with its transactions and reminders.
  Future<void> remove(String id) => _repository.remove(id);
}
