import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/category.dart';
import '../../../data/providers.dart';

part 'categories_providers.g.dart';

/// Every category, groups and hidden ones included, in sort order. Screens
/// build their groups from it with `groupCategories`, and reordering needs
/// the whole list anyway.
@riverpod
Stream<List<Category>> categories(Ref ref) =>
    ref.watch(categoriesRepositoryProvider).watchAll();
