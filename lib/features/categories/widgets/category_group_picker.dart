import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../core/widgets/picker_row.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/category.dart';
import '../providers/categories_providers.dart';

/// Picks the group a category belongs to, hidden groups included. "New
/// group" opens the group editor and dismisses the sheet. Returns the chosen
/// group id, `null` when dismissed.
Future<String?> showCategoryGroupPicker(
  BuildContext context, {
  required CategoryKind kind,
  String? selectedId,
}) => showPickerSheet<String>(
  context,
  (context) => _GroupPicker(kind: kind, selectedId: selectedId),
);

class _GroupPicker extends ConsumerWidget {
  const _GroupPicker({required this.kind, this.selectedId});

  final CategoryKind kind;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final all = ref.watch(categoriesProvider).value ?? const <Category>[];
    return PickerSheet(
      title: l10n.fieldGroup,
      footer: [
        OutlinedButton(
          onPressed: () {
            final router = GoRouter.of(context);
            Navigator.pop(context);
            router.push(Routes.newCategoryGroup(kind));
          },
          child: Text(l10n.editorNewCategoryGroup),
        ),
      ],
      children: [
        for (final group in all)
          if (group.isGroup && group.kind == kind)
            PickerRow(
              title: group.name,
              subtitle: group.isHidden ? l10n.categoryHidden : null,
              leading: CategoryAvatar(
                icon: categoryIcon(group.icon),
                color: Color(group.color!),
              ),
              selected: group.id == selectedId,
              onTap: () => Navigator.pop(context, group.id),
            ),
      ],
    );
  }
}
