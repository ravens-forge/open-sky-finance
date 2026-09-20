import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/result.dart';
import '../../../core/widgets/category_pickers.dart';
import '../../../core/widgets/editor_type_tabs.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/field_row.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_draft.dart';
import '../../../data/repositories/repository_data_error.dart';
import '../models/category_editor_data.dart';
import '../providers/categories_controller.dart';
import '../providers/categories_providers.dart';
import 'category_delete_section.dart';
import 'category_group_picker.dart';
import 'category_usage_note.dart';

/// Name, type (create only), group, icon, colour and hidden; Save pops.
/// Editing adds what uses it and Delete.
class CategoryForm extends ConsumerStatefulWidget {
  const CategoryForm({
    super.key,
    required this.data,
    required this.kind,
    required this.parentId,
  });

  final CategoryEditorData data;

  /// Type of a new category: the tab or group it was created from.
  final CategoryKind kind;

  /// Group pre-selected for a new category.
  final String? parentId;

  @override
  ConsumerState<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<CategoryForm> {
  late final _category = widget.data.category;
  late final _name = TextEditingController(text: _category?.name);
  late var _kind = _category?.kind ?? widget.kind;
  late var _parentId = _category?.parentId ?? widget.parentId;
  late var _icon = _category?.icon ?? 'category';
  late var _color = _category?.color;
  late var _hidden = _category?.isHidden ?? false;
  String? _nameError;
  String? _groupError;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    setState(() {
      _nameError = name.isEmpty ? l10n.errorNameRequired : null;
      _groupError = _parentId == null ? l10n.errorGroupRequired : null;
    });
    if (_nameError != null || _groupError != null) return;

    setState(() => _saving = true);
    final result = await ref
        .read(categoriesControllerProvider.notifier)
        .save(
          CategoryDraft(
            id: _category?.id,
            name: name,
            kind: _kind,
            parentId: _parentId,
            icon: _icon,
            color: _color,
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
      case Err():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final all = ref.watch(categoriesProvider).value ?? const <Category>[];
    final group = all.where((c) => c.id == _parentId).firstOrNull;
    final color = Color(_color ?? group?.color ?? categoryColors.first);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _category == null ? l10n.editorNewCategory : l10n.editorEditCategory,
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
          if (_category == null)
            EditorTypeTabs<CategoryKind>(
              tabs: [
                (
                  CategoryKind.expense,
                  CategoryKind.expense.label(l10n),
                  finance.expense,
                ),
                (
                  CategoryKind.income,
                  CategoryKind.income.label(l10n),
                  finance.income,
                ),
              ],
              selected: _kind,
              onChanged: (kind) => setState(() {
                _kind = kind;
                if (group != null && group.kind != kind) _parentId = null;
              }),
            )
          else ...[
            FieldRow(
              label: l10n.fieldType,
              value: _kind.label(l10n),
              onTap: null,
            ),
            Text(l10n.categoryTypeLocked, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          FieldRow(
            label: l10n.fieldGroup,
            value: group?.name ?? l10n.errorGroupRequired,
            onTap: () async {
              final picked = await showCategoryGroupPicker(
                context,
                kind: _kind,
                selectedId: _parentId,
              );
              if (picked != null) {
                setState(() {
                  _parentId = picked;
                  _groupError = null;
                });
              }
            },
          ),
          if (_groupError case final error?)
            FieldError(error)
          else if (_category != null)
            Text(l10n.categoryMoveNote, style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          Text(l10n.fieldIcon, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          CategoryIconPicker(
            selected: _icon,
            color: color,
            onSelected: (icon) => setState(() => _icon = icon),
          ),
          const SizedBox(height: 20),
          Text(l10n.fieldColor, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          CategoryColorPicker(
            selected: _color,
            groupColor: group?.color,
            onSelected: (value) => setState(() => _color = value),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.categoryHidden),
            subtitle: Text(l10n.categoryHiddenNote),
            value: _hidden,
            onChanged: (on) => setState(() => _hidden = on),
          ),
          if (_category case final category?) ...[
            const SizedBox(height: 24),
            CategoryUsageNote(widget.data.usage),
            const SizedBox(height: 24),
            CategoryDeleteSection(category: category, usage: widget.data.usage),
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
}
