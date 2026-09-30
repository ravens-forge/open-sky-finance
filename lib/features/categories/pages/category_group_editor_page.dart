import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/enums/category_kind.dart';
import '../providers/category_editor_provider.dart';
import '../widgets/category_group_form.dart';
import '../../shell/widgets/page_load_error.dart';

/// Creates ([id] `null`) or edits a category group.
class CategoryGroupEditorPage extends ConsumerWidget {
  const CategoryGroupEditorPage({
    super.key,
    this.id,
    this.kind = CategoryKind.income,
  });

  final String? id;

  /// Type of a new group.
  final CategoryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(categoryGroupEditorDataProvider(id))) {
      AsyncValue(:final value?) => CategoryGroupForm(data: value, kind: kind),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: PageLoadError(providers: [categoryGroupEditorDataProvider(id)]),
      ),
      _ => Scaffold(appBar: AppBar()),
    };
  }
}
