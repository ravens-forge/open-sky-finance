import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/providers.dart';
import '../models/trash_day.dart';

part 'trash_providers.g.dart';

@riverpod
Stream<List<TrashDay>> trash(Ref ref) => ref
    .watch(transactionsRepositoryProvider)
    .watchTrash()
    .map(TrashDay.groupsOf);
