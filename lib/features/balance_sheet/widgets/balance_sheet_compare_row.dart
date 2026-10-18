import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/setting_keys.dart';
import '../models/balance_sheet_compare_kind.dart';
import '../models/balance_sheet_comparison.dart';

/// "Compare with" and the chosen comparison; a tap opens the choices, each
/// with its date for [asOf], and saves the one picked.
class BalanceSheetCompareRow extends ConsumerWidget {
  const BalanceSheetCompareRow({
    super.key,
    required this.comparison,
    required this.asOf,
  });

  final BalanceSheetComparison comparison;
  final DateTime asOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final date = DateFormat.yMMMd(l10n.localeName);
    String label(BalanceSheetCompareKind kind) => switch (kind) {
      BalanceSheetCompareKind.sameDayLastMonth =>
        l10n.balanceSheetCompareSameDayLastMonth,
      BalanceSheetCompareKind.endOfLastMonth =>
        l10n.balanceSheetCompareEndOfLastMonth,
      BalanceSheetCompareKind.sameDayLastYear =>
        l10n.balanceSheetCompareSameDayLastYear,
      BalanceSheetCompareKind.endOfLastYear =>
        l10n.balanceSheetCompareEndOfLastYear,
      BalanceSheetCompareKind.pickedDate => switch (comparison.picked) {
        final picked? when comparison.kind == kind => date.format(picked),
        _ => l10n.balanceSheetComparePickDate,
      },
      BalanceSheetCompareKind.none => l10n.balanceSheetCompareNone,
    };

    Future<void> choose() async {
      final kind = await showChoiceSheet(
        context,
        title: l10n.balanceSheetCompareWith,
        options: [
          for (final kind in BalanceSheetCompareKind.values)
            switch (BalanceSheetComparison(kind).dateFor(asOf)) {
              final day? => (
                kind,
                l10n.balanceSheetCompareOption(label(kind), date.format(day)),
              ),
              null => (kind, label(kind)),
            },
        ],
        selected: comparison.kind,
      );
      if (kind == null || !context.mounted) return;
      var next = BalanceSheetComparison(kind);
      if (kind == BalanceSheetCompareKind.pickedDate) {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              comparison.picked ?? BalanceSheetComparison.initial.dateFor(asOf),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          helpText: l10n.balanceSheetCompareWith,
        );
        if (picked == null) return;
        next = BalanceSheetComparison(kind, picked);
      }
      await ref
          .read(settingsRepositoryProvider)
          .set(SettingKeys.balanceSheetComparison, next.encode());
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.balanceSheetCompareWith.toUpperCase(),
          style: Theme.of(context).textTheme.eyebrow,
        ),
        TextButton.icon(
          onPressed: choose,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.expand_more, size: 16),
          label: Text(
            label(comparison.kind),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
