import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/providers.dart';

part 'trash_controller.g.dart';

@Riverpod(keepAlive: true)
class TrashController extends _$TrashController {
  @override
  FutureOr<void> build() {}

  /// A deleted category leaves it uncategorized.
  Future<void> restore(String id) =>
      ref.read(transactionsRepositoryProvider).restore(id);

  Future<void> deletePermanently(String id) =>
      ref.read(transactionsRepositoryProvider).deletePermanently(id);

  Future<void> empty() => ref.read(transactionsRepositoryProvider).emptyTrash();
}
