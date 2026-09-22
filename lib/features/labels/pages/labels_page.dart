import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/main_currency.dart';
import '../../../app/routes.dart';
import '../../../core/dates/year_month.dart';
import '../../../core/l10n.dart';
import '../../../core/money/currency_converter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_tooltip.dart';
import '../../../core/widgets/month_switcher.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../data/models/label.dart';
import '../../../data/models/label_total.dart';
import '../../../data/models/transaction_filter.dart';
import '../../transactions/providers/transactions_drill_down.dart';
import '../providers/labels_controller.dart';
import '../providers/labels_providers.dart';
import '../widgets/delete_label_dialog.dart';
import '../widgets/label_name_dialog.dart';
import '../widgets/label_total_row.dart';

class LabelsPage extends ConsumerStatefulWidget {
  const LabelsPage({super.key});

  @override
  ConsumerState<LabelsPage> createState() => _LabelsPageState();
}

class _LabelsPageState extends ConsumerState<LabelsPage> {
  var _month = YearMonth.of(DateTime.now());

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month.start,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: context.l10n.transactionsPickMonth,
    );
    if (picked != null) setState(() => _month = YearMonth.of(picked));
  }

  void _open(Label label) {
    ref
        .read(transactionsDrillDownProvider.notifier)
        .show(_month, TransactionFilter(labelId: label.id));
    context.go(Routes.transactions);
  }

  Future<void> _delete(Label label) async {
    final controller = ref.read(labelsControllerProvider.notifier);
    final uses = await controller.uses(label.id);
    if (!mounted) return;
    final confirmed = await showDeleteLabelDialog(
      context,
      label: label,
      uses: uses,
    );
    if (confirmed) {
      await controller.remove(label.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totals = ref.watch(labelTotalsProvider(_month));
    final converter = ref.watch(currencyConverterProvider).value;
    return Column(
      children: [
        MonthSwitcher(
          month: _month,
          onChanged: (month) => setState(() => _month = month),
          onPick: _pickMonth,
        ),
        const Divider(),
        Expanded(
          child: switch ((totals, converter)) {
            (AsyncError(), _) => Center(
              child: EmptyState(title: l10n.errorLoadFailed),
            ),
            (AsyncData(value: []), _) => Center(
              child: EmptyState(
                title: l10n.labelsEmpty,
                message: l10n.labelsEmptyMessage,
                actions: [_newButton()],
              ),
            ),
            (AsyncData(:final value), final CurrencyConverter converter) =>
              _list(value, converter),
            _ => PagePlaceholder(label: l10n.pageLabels),
          },
        ),
      ],
    );
  }

  Widget _newButton() => OutlinedButton.icon(
    onPressed: () => showLabelNameDialog(context),
    icon: const Icon(Icons.add, size: 18),
    label: Text(context.l10n.labelsNew),
  );

  Widget _list(List<LabelTotal> totals, CurrencyConverter converter) {
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
            converter: converter,
            onTap: () => _open(total.label),
            onRename: () => showLabelNameDialog(context, label: total.label),
            onDelete: () => _delete(total.label),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.colorScheme.onSurface)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _newButton(),
            ),
          ),
        ),
      ],
    );
  }
}
