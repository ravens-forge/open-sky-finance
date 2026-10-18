import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../app/default_currency.dart';
import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../core/dates/year_month.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_tooltip.dart';
import '../../../core/widgets/month_switcher.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../data/models/label.dart';
import '../../../data/models/label_total.dart';
import '../../../data/models/transaction_filter.dart';
import '../../../data/providers.dart';
import '../../shell/widgets/page_load_error.dart';
import '../../transactions/providers/transactions_drill_down.dart';
import '../providers/labels_providers.dart';
import '../widgets/delete_label_dialog.dart';
import '../widgets/label_name_dialog.dart';
import '../widgets/label_total_row.dart';

class LabelsPage extends HookConsumerWidget {
  const LabelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = useState(useMemoized(() => ref.read(currentMonthProvider)));

    Future<void> pickMonth() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: month.value.start,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        initialDatePickerMode: DatePickerMode.year,
        helpText: l10n.transactionsPickMonth,
      );
      if (picked != null) month.value = YearMonth.of(picked);
    }

    void open(Label label) {
      ref
          .read(transactionsDrillDownProvider.notifier)
          .show(month.value, TransactionFilter(labelId: label.id));
      context.go(Routes.transactions);
    }

    Future<void> delete(Label label) async {
      final repository = ref.read(labelsRepositoryProvider);
      final uses = await repository.uses(label.id);
      if (!context.mounted) return;
      final confirmed = await showDeleteLabelDialog(
        context,
        label: label,
        uses: uses,
      );
      if (confirmed) {
        await repository.remove(label.id);
      }
    }

    final totals = ref.watch(labelTotalsProvider(month.value));
    final fallback = ref.watch(defaultCurrencyProvider).value;
    return Column(
      children: [
        MonthSwitcher(
          month: month.value,
          onChanged: (value) => month.value = value,
          onPick: pickMonth,
        ),
        const Divider(),
        Expanded(
          child: switch ((totals, fallback)) {
            (AsyncError(), _) => PageLoadError(
              providers: [labelTotalsProvider(month.value)],
            ),
            (AsyncValue(value: []), _) => Center(
              child: EmptyState(
                title: l10n.labelsEmpty,
                message: l10n.labelsEmptyMessage,
                actions: const [_NewLabelButton()],
              ),
            ),
            (AsyncValue(:final value?), final String fallback) => _LabelList(
              totals: value,
              defaultCurrency: fallback,
              onOpen: open,
              onDelete: delete,
            ),
            _ => PagePlaceholder(label: l10n.pageLabels),
          },
        ),
      ],
    );
  }
}

class _NewLabelButton extends StatelessWidget {
  const _NewLabelButton();

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => showLabelNameDialog(context),
    icon: const Icon(Icons.add, size: 18),
    label: Text(context.l10n.labelsNew),
  );
}

class _LabelList extends StatelessWidget {
  const _LabelList({
    required this.totals,
    required this.defaultCurrency,
    required this.onOpen,
    required this.onDelete,
  });

  final List<LabelTotal> totals;
  final String defaultCurrency;
  final ValueChanged<Label> onOpen;
  final ValueChanged<Label> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n.labelsIntro,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -12),
                child: InfoTooltip(
                  label: l10n.labelsInfoLabel,
                  eyebrow: l10n.labelsInfoEyebrow.toUpperCase(),
                  text: l10n.labelsInfo,
                ),
              ),
            ],
          ),
        ),
        for (final total in totals)
          LabelTotalRow(
            total: total,
            defaultCurrency: defaultCurrency,
            onTap: () => onOpen(total.label),
            onRename: () => showLabelNameDialog(context, label: total.label),
            onDelete: () => onDelete(total.label),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.colorScheme.onSurface)),
          ),
          child: const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _NewLabelButton(),
            ),
          ),
        ),
      ],
    );
  }
}
