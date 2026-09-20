import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/category.dart';
import '../../../data/models/category_group.dart';
import '../../../data/providers.dart';

part 'categories_providers.g.dart';

/// Every group, hidden ones included, in sort order.
@riverpod
Stream<List<CategoryGroup>> categoryGroups(Ref ref) =>
    ref.watch(categoriesRepositoryProvider).watchGroups();

/// Every category, hidden ones included, in sort order. Screens build their
/// groups from both lists with `groupCategories`, and reordering needs the
/// whole list anyway.
@riverpod
Stream<List<Category>> categories(Ref ref) =>
    ref.watch(categoriesRepositoryProvider).watchCategories();
