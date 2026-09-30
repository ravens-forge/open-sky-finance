import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/enums/category_kind.dart';
import '../providers/category_editor_provider.dart';
import '../widgets/category_form.dart';
import '../../shell/widgets/page_load_error.dart';

/// Creates ([id] `null`) or edits a category.
class CategoryEditorPage extends ConsumerWidget {
  const CategoryEditorPage({
    super.key,
    this.id,
    this.kind = CategoryKind.income,
    this.groupId,
  });

  final String? id;

  /// Type of a new category.
  final CategoryKind kind;

  /// Group of a new category, when it is created from one.
  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(categoryEditorDataProvider(id))) {
      AsyncValue(:final value?) => CategoryForm(
        data: value,
        kind: kind,
        groupId: groupId,
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: PageLoadError(providers: [categoryEditorDataProvider(id)]),
      ),
      _ => Scaffold(appBar: AppBar()),
    };
  }
}
