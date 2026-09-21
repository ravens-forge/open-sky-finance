import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/result.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/type_selector.dart';
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
class CategoryGroupForm extends ConsumerStatefulWidget {
  const CategoryGroupForm({super.key, required this.data, required this.kind});

  final CategoryEditorData data;

  /// Type a new group starts on.
  final CategoryKind kind;

  @override
  ConsumerState<CategoryGroupForm> createState() => _CategoryGroupFormState();
}

class _CategoryGroupFormState extends ConsumerState<CategoryGroupForm> {
  late final _group = widget.data.group;
  late final _name = TextEditingController(text: _group?.name);
  late var _kind = _group?.kind ?? widget.kind;
  late var _hidden = _group?.isHidden ?? false;
  String? _nameError;
  var _saving = false;

  /// The type is fixed once categories or their transactions hang from it.
  bool get _kindLocked =>
      widget.data.usage.categories > 0 || widget.data.usage.transactions > 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    setState(() => _nameError = name.isEmpty ? l10n.errorNameRequired : null);
    if (_nameError != null) return;

    setState(() => _saving = true);
    final result = await ref
        .read(categoriesControllerProvider.notifier)
        .saveGroup(
          CategoryGroupDraft(
            id: _group?.id,
            name: name,
            kind: _kind,
            isHidden: _hidden,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        context.pop();
      case Err(error: RepositoryDataError.invalidName):
        setState(() => _nameError = l10n.errorNameRequired);
      case Err(error: RepositoryDataError.kindLocked):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorCategoryKindLocked)));
      case Err():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _group == null
              ? l10n.editorNewCategoryGroup
              : l10n.editorEditCategoryGroup,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.fieldName,
              error: _nameError == null ? null : FieldError(_nameError!),
            ),
          ),
          const SizedBox(height: 20),
          TypeSelector<CategoryKind>(
            options: [
              for (final kind in CategoryKind.values) (kind, kind.label(l10n)),
            ],
            selected: _kind,
            locked: _kindLocked,
            onChanged: (kind) => setState(() => _kind = kind),
          ),
          if (_kindLocked)
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
            value: _hidden,
            onChanged: (on) => setState(() => _hidden = on),
          ),
          if (_group case final group?) ...[
            const SizedBox(height: 24),
            _categories(group),
            const SizedBox(height: 24),
            CategoryDeleteSection(group: group, usage: widget.data.usage),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.actionCancel),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.actionSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The categories of the group: open, reorder, or add another one.
  Widget _categories(CategoryGroup group) {
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
              context.push(Routes.newCategory(_kind, groupId: group.id)),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.categoryAdd),
        ),
      ],
    );
  }
}
