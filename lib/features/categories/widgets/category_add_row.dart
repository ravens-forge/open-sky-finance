import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../data/models/category.dart';

/// Last row of an expanded group: "Add category to …", preceded by "No
/// categories yet" while the group is still empty.
class CategoryAddRow extends StatelessWidget {
  const CategoryAddRow({super.key, required this.group, required this.isEmpty});

  final Category group;

  /// The group has no categories yet.
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(60, 8, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          if (isEmpty)
            Text(l10n.categoriesEmptyGroup, style: theme.textTheme.bodySmall),
          OutlinedButton.icon(
            onPressed: () => context.push(
              Routes.newCategory(group.kind, parentId: group.id),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.categoriesAddTo(group.name)),
          ),
        ],
      ),
    );
  }
}
