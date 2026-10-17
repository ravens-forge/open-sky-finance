import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/money/parse_money.dart';
import '../../../core/result.dart';
import '../../../core/widgets/above_keyboard.dart';
import '../../../core/widgets/button_row.dart';
import '../../../core/widgets/info_note.dart';
import '../../../data/providers.dart';
import '../models/budget_editor_data.dart';
import 'edit_budget_row.dart';

class EditBudgetsForm extends HookConsumerWidget {
  const EditBudgetsForm({super.key, required this.data});

  final BudgetEditorData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = l10n.localeName;
    // By group or category id, written in the locale of the first build.
    final fields = useMemoized(
      () => {
        for (final node in data.groups)
          for (final id in [
            node.group.id,
            for (final c in node.categories) c.id,
          ])
            id: TextEditingController(
              text: switch (data.budgets[id]) {
                null => '',
                final budget => formatMoney(
                  budget,
                  currency: data.currency,
                  locale: locale,
                  symbol: false,
                ),
              },
            ),
      },
    );
    useEffect(
      () => () {
        for (final field in fields.values) {
          field.dispose();
        }
      },
      const [],
    );
    // The total and the "covered by group" notes follow what is typed.
    useListenable(useMemoized(() => Listenable.merge(fields.values)));
    final invalid = useState(const <String>{});
    final saving = useState(false);

    // The amount typed for [id]: `null` when empty or not a positive amount.
    int? amountOf(String id) {
      final amount = parseMoney(fields[id]!.text, locale: locale);
      return amount != null && amount > 0 ? amount : null;
    }

    Future<void> save() async {
      final changes = <String, int?>{};
      final wrong = <String>{};
      for (final MapEntry(key: id, value: field) in fields.entries) {
        final amount = amountOf(id);
        if (amount == null && field.text.trim().isNotEmpty) {
          wrong.add(id);
        } else if (amount != data.budgets[id]) {
          changes[id] = amount;
        }
      }
      invalid.value = wrong;
      if (wrong.isNotEmpty) return;

      saving.value = true;
      final result = await ref.read(budgetsRepositoryProvider).setAll(changes);
      if (!context.mounted) return;
      saving.value = false;
      switch (result) {
        case Ok():
          context.pop();
        case Err():
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
      }
    }

    String money(int micros) =>
        formatMoney(micros, currency: data.currency, locale: locale);
    final month = DateFormat.MMMM(locale).format(data.month.start);
    void changed(String id) {
      if (invalid.value.contains(id)) {
        invalid.value = {...invalid.value}..remove(id);
      }
    }

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
              controller: fields[node.group.id]!,
              currency: data.currency,
              invalid: invalid.value.contains(node.group.id),
              onChanged: (_) => changed(node.group.id),
            ),
            for (final category in node.categories)
              EditBudgetRow(
                name: category.name,
                note: amountOf(node.group.id) != null
                    ? l10n.budgetCoveredByGroup
                    : l10n.budgetSpentAmount(
                        money(data.spent[category.id] ?? 0),
                      ),
                isGroup: false,
                controller: fields[category.id]!,
                currency: data.currency,
                invalid: invalid.value.contains(category.id),
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
                    fields.keys.fold(0, (sum, id) => sum + (amountOf(id) ?? 0)),
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
      bottomNavigationBar: AboveKeyboard(
        child: DecoratedBox(
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
                    onPressed: saving.value ? null : save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    child: Text(l10n.budgetSave, textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
