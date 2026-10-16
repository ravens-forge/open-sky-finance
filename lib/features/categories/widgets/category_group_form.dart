import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/result.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/type_selector.dart';
import '../../../core/widgets/button_row.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_group.dart';
import '../../../data/models/category_group_draft.dart';
import '../../../data/repositories/repository_data_error.dart';
import '../models/category_editor_data.dart';
import '../providers/categories_controller.dart';
import '../providers/categories_providers.dart';
import 'category_delete_section.dart';
import 'category_row.dart';

/// Name, type (locked once the group is in use) and hidden, plus the
/// categories inside it. A group has no icon and no colour to pick: it is
/// drawn in the colour of its type.
class CategoryGroupForm extends HookConsumerWidget {
  const CategoryGroupForm({super.key, required this.data, required this.kind});

  final CategoryEditorData data;

  /// Type a new group starts on.
  final CategoryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final group = data.group;
    final name = useTextEditingController(text: group?.name);
    final selectedKind = useState(group?.kind ?? kind);
    final hidden = useState(group?.isHidden ?? false);
    final nameError = useState<String?>(null);
    final saving = useState(false);
    // The type is fixed once categories or their transactions hang from it.
    final kindLocked = data.usage.categories > 0 || data.usage.transactions > 0;

    Future<void> save() async {
      final trimmed = name.text.trim();
      nameError.value = trimmed.isEmpty ? l10n.errorNameRequired : null;
      if (nameError.value != null) return;

      saving.value = true;
      final result = await ref
          .read(categoriesControllerProvider.notifier)
          .saveGroup(
            CategoryGroupDraft(
              id: group?.id,
              name: trimmed,
              kind: selectedKind.value,
              isHidden: hidden.value,
            ),
          );
      if (!context.mounted) return;
      saving.value = false;
      switch (result) {
        case Ok():
          context.pop();
        case Err(error: RepositoryDataError.invalidName):
          nameError.value = l10n.errorNameRequired;
        case Err(error: RepositoryDataError.kindLocked):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.errorCategoryKindLocked)));
        case Err():
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          group == null
              ? l10n.editorNewCategoryGroup
              : l10n.editorEditCategoryGroup,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.fieldName,
              error: nameError.value == null
                  ? null
                  : FieldError(nameError.value!),
            ),
          ),
          const SizedBox(height: 20),
          TypeSelector<CategoryKind>(
            options: [
              for (final k in CategoryKind.values) (k, k.signedLabel(l10n)),
            ],
            selected: selectedKind.value,
            locked: kindLocked,
            onChanged: (value) => selectedKind.value = value,
          ),
          if (kindLocked)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.categoryGroupTypeLocked,
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.categoryHidden),
            subtitle: Text(l10n.categoryGroupHiddenNote),
            value: hidden.value,
            onChanged: (on) => hidden.value = on,
          ),
          if (group != null) ...[
            const SizedBox(height: 24),
            _GroupCategories(group: group, kind: selectedKind.value),
            const SizedBox(height: 24),
            CategoryDeleteSection(group: group, usage: data.usage),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ButtonRow(
            children: [
              OutlinedButton(
                onPressed: () => context.pop(),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: saving.value ? null : save,
                child: Text(l10n.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The categories of the group: open, reorder, or add another one.
class _GroupCategories extends ConsumerWidget {
  const _GroupCategories({required this.group, required this.kind});

  final CategoryGroup group;
  final CategoryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final all = ref.watch(categoriesProvider).value ?? const <Category>[];
    final categories = [
      for (final category in all)
        if (category.groupId == group.id) category,
    ];
    final ids = [for (final category in categories) category.id];
    final allIds = [for (final category in all) category.id];
    void move(int from, int to) {
      if (from != to) {
        ref
            .read(categoriesControllerProvider.notifier)
            .move(allIds, ids, from, to);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          l10n.categoryGroupCategories.toUpperCase(),
          style: theme.textTheme.eyebrow,
        ),
        if (categories.isEmpty)
          Text(l10n.categoriesEmptyGroup, style: theme.textTheme.bodySmall)
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: move,
            children: [
              for (final (i, category) in categories.indexed)
                CategoryRow(
                  key: ValueKey(category.id),
                  category: category,
                  index: i,
                  onTap: () => context.push(Routes.category(category.id)),
                  onMoveUp: i > 0 ? () => move(i, i - 1) : null,
                  onMoveDown: i < ids.length - 1 ? () => move(i, i + 1) : null,
                ),
            ],
          ),
        TextButton.icon(
          onPressed: () =>
              context.push(Routes.newCategory(kind, groupId: group.id)),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.categoryAdd),
        ),
      ],
    );
  }
}
