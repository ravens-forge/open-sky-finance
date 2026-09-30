import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/money/parse_money.dart';
import '../../../core/result.dart';
import '../../../core/widgets/button_row.dart';
import '../../../core/widgets/info_note.dart';
import '../models/budget_editor_data.dart';
import '../providers/budgets_controller.dart';
import 'edit_budget_row.dart';

class EditBudgetsForm extends ConsumerStatefulWidget {
  const EditBudgetsForm({super.key, required this.data});

  final BudgetEditorData data;

  @override
  ConsumerState<EditBudgetsForm> createState() => _EditBudgetsFormState();
}

class _EditBudgetsFormState extends ConsumerState<EditBudgetsForm> {
  /// By group or category id. Filled on the first build, which knows the
  /// locale the amounts are written in.
  final _fields = <String, TextEditingController>{};
  var _invalid = <String>{};
  var _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fields.isNotEmpty) return;
    final data = widget.data;
    for (final node in data.groups) {
      for (final id in [node.group.id, for (final c in node.categories) c.id]) {
        final budget = data.budgets[id];
        _fields[id] = TextEditingController(
          text: budget == null
              ? ''
              : formatMoney(
                  budget,
                  currency: data.currency,
                  locale: context.l10n.localeName,
                  symbol: false,
                ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  /// The amount typed for [id]: `null` when empty or not a positive amount.
  int? _amount(String id) {
    final amount = parseMoney(
      _fields[id]!.text,
      locale: context.l10n.localeName,
    );
    return amount != null && amount > 0 ? amount : null;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final changes = <String, int?>{};
    final invalid = <String>{};
    for (final MapEntry(key: id, value: field) in _fields.entries) {
      final amount = _amount(id);
      if (amount == null && field.text.trim().isNotEmpty) {
        invalid.add(id);
      } else if (amount != widget.data.budgets[id]) {
        changes[id] = amount;
      }
    }
    setState(() => _invalid = invalid);
    if (invalid.isNotEmpty) return;

    setState(() => _saving = true);
    final result = await ref
        .read(budgetsControllerProvider.notifier)
        .save(changes);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        context.pop();
      case Err():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = widget.data;
    final locale = l10n.localeName;
    String money(int micros) =>
        formatMoney(micros, currency: data.currency, locale: locale);
    final month = DateFormat.MMMM(locale).format(data.month.start);
    void changed(String id) => setState(() => _invalid.remove(id));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetEdit)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          InfoNote(l10n.budgetEditIntro(data.currency)),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              l10n.budgetEditCaption,
              style: theme.textTheme.bodySmall!.copyWith(fontSize: 13),
            ),
          ),
          for (final node in data.groups) ...[
            EditBudgetRow(
              name: node.group.name,
              note: l10n.budgetSpentInMonth(
                money(
                  node.categories.fold(
                    0,
                    (sum, c) => sum + (data.spent[c.id] ?? 0),
                  ),
                ),
                month,
              ),
              isGroup: true,
              controller: _fields[node.group.id]!,
              currency: data.currency,
              invalid: _invalid.contains(node.group.id),
              onChanged: (_) => changed(node.group.id),
            ),
            for (final category in node.categories)
              EditBudgetRow(
                name: category.name,
                note: _amount(node.group.id) != null
                    ? l10n.budgetCoveredByGroup
                    : l10n.budgetSpentAmount(
                        money(data.spent[category.id] ?? 0),
                      ),
                isGroup: false,
                controller: _fields[category.id]!,
                currency: data.currency,
                invalid: _invalid.contains(category.id),
                onChanged: (_) => changed(category.id),
              ),
          ],
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: scheme.onSurface, width: 3),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(
                  l10n.budgetTotalBudgeted,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  money(
                    _fields.keys.fold(0, (sum, id) => sum + (_amount(id) ?? 0)),
                  ),
                  style: theme.textTheme.sectionTitle.copyWith(fontSize: 26),
                ),
              ],
            ),
          ),
          Text(
            l10n.budgetIncomeNever,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: ButtonRow(
              spacing: 10,
              children: [
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: Text(l10n.actionCancel),
                ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: Text(l10n.budgetSave, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
