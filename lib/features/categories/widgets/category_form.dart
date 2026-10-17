import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/result.dart';
import '../../../core/widgets/above_keyboard.dart';
import '../../../core/widgets/button_row.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/field_row.dart';
import '../../../core/widgets/type_selector.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/category_draft.dart';
import '../../../data/models/category_group.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/repository_data_error.dart';
import '../models/category_editor_data.dart';
import '../providers/categories_providers.dart';
import 'category_delete_section.dart';
import 'category_group_picker.dart';
import 'category_pickers.dart';
import 'category_usage_note.dart';

/// Name, group, icon, colour and hidden; Save pops. Editing adds what uses it
/// and Delete. The type is not stored on a category: it comes from its group,
/// and the selector here only narrows the groups on offer.
class CategoryForm extends HookConsumerWidget {
  const CategoryForm({
    super.key,
    required this.data,
    required this.kind,
    required this.groupId,
  });

  final CategoryEditorData data;

  /// Type a new category starts on.
  final CategoryKind kind;

  /// Group pre-selected for a new category.
  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final category = data.category;
    final name = useTextEditingController(text: category?.name);
    final kind = useState(data.group?.kind ?? this.kind);
    final selectedGroupId = useState(category?.groupId ?? groupId);
    final icon = useState(category?.icon ?? 'category');
    final color = useState(category?.color ?? categoryColors.first);
    final hidden = useState(category?.isHidden ?? false);
    final nameError = useState<String?>(null);
    final groupError = useState<String?>(null);
    final saving = useState(false);

    Future<void> save() async {
      final trimmed = name.text.trim();
      nameError.value = trimmed.isEmpty ? l10n.errorNameRequired : null;
      groupError.value = selectedGroupId.value == null
          ? l10n.errorGroupRequired
          : null;
      if (nameError.value != null || selectedGroupId.value == null) return;

      saving.value = true;
      final result = await ref
          .read(categoriesRepositoryProvider)
          .saveCategory(
            CategoryDraft(
              id: category?.id,
              name: trimmed,
              groupId: selectedGroupId.value!,
              icon: icon.value,
              color: color.value,
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
        case Err(error: RepositoryDataError.categoryKindMismatch):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.errorCategoryKindLocked)));
        case Err():
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
      }
    }

    final groups = ref.watch(categoryGroupsProvider).value ?? const [];
    final group = groups
        .where((CategoryGroup g) => g.id == selectedGroupId.value)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category == null ? l10n.editorNewCategory : l10n.editorEditCategory,
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
            selected: kind.value,
            locked: category != null,
            onChanged: (value) {
              kind.value = value;
              if (group != null && group.kind != value) {
                selectedGroupId.value = null;
              }
            },
          ),
          if (category != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.categoryTypeLocked,
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          FieldRow(
            label: l10n.fieldGroup,
            value: group?.name ?? l10n.errorGroupRequired,
            onTap: () async {
              final picked = await showCategoryGroupPicker(
                context,
                kind: kind.value,
                selectedId: selectedGroupId.value,
              );
              if (picked != null) {
                selectedGroupId.value = picked;
                groupError.value = null;
              }
            },
          ),
          if (groupError.value case final error?)
            FieldError(error)
          else if (category != null)
            Text(l10n.categoryMoveNote, style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          Text(l10n.fieldIcon, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          CategoryIconPicker(
            selected: icon.value,
            color: Color(color.value),
            onSelected: (value) => icon.value = value,
          ),
          const SizedBox(height: 20),
          Text(l10n.fieldColor, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          CategoryColorPicker(
            selected: color.value,
            onSelected: (value) => color.value = value,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.categoryHidden),
            subtitle: Text(l10n.categoryHiddenNote),
            value: hidden.value,
            onChanged: (on) => hidden.value = on,
          ),
          if (category != null) ...[
            const SizedBox(height: 24),
            CategoryUsageNote(data.usage),
            const SizedBox(height: 24),
            CategoryDeleteSection(category: category, usage: data.usage),
          ],
        ],
      ),
      bottomNavigationBar: AboveKeyboard(
        child: SafeArea(
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
      ),
    );
  }
}
