@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:open_sky_finance/core/dates/year_month.dart';
import 'package:open_sky_finance/core/finance_colors.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/labels.dart';
import 'package:open_sky_finance/core/widgets/amount_text.dart';
import 'package:open_sky_finance/core/widgets/budget_bar.dart';
import 'package:open_sky_finance/core/widgets/category_avatar.dart';
import 'package:open_sky_finance/core/widgets/day_header.dart';
import 'package:open_sky_finance/core/widgets/destructive_button.dart';
import 'package:open_sky_finance/core/widgets/field_error.dart';
import 'package:open_sky_finance/core/widgets/form_error_summary.dart';
import 'package:open_sky_finance/core/widgets/home_section_header.dart';
import 'package:open_sky_finance/core/widgets/info_note.dart';
import 'package:open_sky_finance/core/widgets/info_tooltip.dart';
import 'package:open_sky_finance/core/widgets/leader_row.dart';
import 'package:open_sky_finance/core/widgets/ledger_chip.dart';
import 'package:open_sky_finance/core/widgets/month_switcher.dart';
import 'package:open_sky_finance/core/widgets/reminder_row.dart';
import 'package:open_sky_finance/core/widgets/segmented_filter.dart';
import 'package:open_sky_finance/core/widgets/transaction_row.dart';
import 'package:open_sky_finance/core/widgets/type_selector.dart';
import 'package:open_sky_finance/core/widgets/warning_banner.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';

import '../data/test_db.dart';
import 'golden.dart';

Widget _amount(num units, [AmountStyle style = AmountStyle.signed]) =>
    AmountText(m(units), currency: 'EUR', amountStyle: style);

/// Chips, selectors, buttons, budget bars, amounts, notes and form errors.
Widget _controls(BuildContext context) {
  final l10n = context.l10n;
  final types = [
    for (final t in [
      TransactionType.income,
      TransactionType.expense,
      TransactionType.transfer,
    ])
      (t, t.label(l10n)),
  ];
  void none(Object? _) {}
  return ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          const LedgerChip.label('vacation'),
          const LedgerChip.label('Checking', icon: Icons.star),
          LedgerChip.outline(l10n.chipAutomatic),
          LedgerChip.add(l10n.actionAdd, icon: Icons.add),
          LedgerChip.scheduled(l10n.chipScheduled, compact: false),
          LedgerChip.overdue(l10n.chipOverdue, compact: false),
        ],
      ),
      const SizedBox(height: 16),
      SegmentedFilter<TransactionType>(
        options: types,
        selected: TransactionType.expense,
        onChanged: none,
      ),
      const SizedBox(height: 16),
      TypeSelector<TransactionType>(
        options: types,
        selected: TransactionType.income,
        onChanged: none,
      ),
      const SizedBox(height: 8),
      TypeSelector<TransactionType>(
        options: types.take(2).toList(),
        selected: TransactionType.expense,
        onChanged: none,
        locked: true,
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton(onPressed: () {}, child: Text(l10n.actionSave)),
          OutlinedButton(onPressed: () {}, child: Text(l10n.actionCancel)),
          TextButton(onPressed: () {}, child: Text(l10n.actionSkip)),
          DestructiveButton(onPressed: () {}, child: Text(l10n.actionDelete)),
        ],
      ),
      const SizedBox(height: 16),
      for (final spent in [400, 850, 1000, 1200]) ...[
        BudgetBar(spentMicros: m(spent), budgetMicros: m(1000)),
        const SizedBox(height: 12),
      ],
      Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _amount(3200),
          _amount(-54.20),
          _amount(450, AmountStyle.transfer),
          _amount(-679.85, AmountStyle.balance),
          _amount(8940.22, AmountStyle.balance),
        ],
      ),
      const SizedBox(height: 16),
      HomeSectionHeader(
        title: l10n.homeSectionCashFlow,
        caption: Text(l10n.homeLastMonths(6)),
      ),
      Row(
        children: [
          Text(l10n.labelsInfoEyebrow.toUpperCase()),
          InfoTooltip(label: l10n.labelsInfoLabel, text: l10n.labelsInfo),
        ],
      ),
      const SizedBox(height: 8),
      InfoNote(l10n.labelsIntro),
      const SizedBox(height: 12),
      WarningBanner(lead: l10n.chipOverdue, text: l10n.errorSaveFailed),
      const SizedBox(height: 12),
      const FormErrorSummary(count: 2),
      const SizedBox(height: 8),
      FieldError(l10n.errorAmountRequired),
    ],
  );
}

/// Day header, month switcher and the ledger rows.
Widget _rows(BuildContext context) {
  final l10n = context.l10n;
  final finance = FinanceColors.of(context);
  final day = DateFormat.MMMMEEEEd(l10n.localeName).format(goldenNow);
  return ListView(
    padding: const EdgeInsets.all(20),
    children: [
      MonthSwitcher(month: YearMonth(2026, 9), onChanged: (_) {}),
      DayHeader(title: day, trailing: _amount(-47.40)),
      TransactionRow(
        icon: Icons.local_grocery_store_outlined,
        iconColor: const Color(categoryColor),
        title: 'Central Market',
        subtitle: l10n.transactionSubtitle('Groceries', 'Wallet'),
        amount: _amount(-42.80),
        labels: const ['vacation'],
      ),
      TransactionRow(
        icon: Icons.home_outlined,
        iconColor: const Color(categoryColor),
        title: 'Rent',
        subtitle: l10n.transactionSubtitle('Housing', 'Checking'),
        amount: _amount(-850),
        scheduled: true,
      ),
      TransactionRow(
        icon: Icons.swap_horiz,
        iconColor: finance.transfer,
        title: 'Monthly savings',
        subtitle: l10n.transferFromTo('Checking', 'Savings'),
        amount: _amount(450, AmountStyle.transfer),
      ),
      ReminderRow(
        icon: Icons.smartphone_outlined,
        iconColor: const Color(categoryColor),
        title: 'Phone bill',
        schedule: l10n.budgetPeriodMonthly,
        due: l10n.chipOverdue,
        overdue: true,
        amount: _amount(-35),
        onRecord: () {},
        onSkip: () {},
      ),
      ReminderRow(
        icon: Icons.savings_outlined,
        iconColor: finance.transfer,
        title: 'Monthly savings',
        schedule: l10n.budgetPeriodMonthly,
        due: DateFormat.MMMd(l10n.localeName).format(DateTime(2026, 9, 25)),
        amount: _amount(450, AmountStyle.transfer),
      ),
      const SizedBox(height: 12),
      LeaderRow(
        name: 'Checking',
        amount: _amount(8940.22, AmountStyle.balance),
      ),
      LeaderRow(name: 'Visa', amount: _amount(-679.85, AmountStyle.balance)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        children: [
          CategoryAvatar(
            icon: Icons.restaurant_outlined,
            color: const Color(categoryColor),
          ),
          CategoryAvatar(
            icon: Icons.sell_outlined,
            color: Theme.of(context).colorScheme.primary,
            background: Theme.of(context).colorScheme.primaryContainer,
          ),
          const CategoryAvatar(
            icon: Icons.movie_outlined,
            color: Color(categoryColor),
            transparent: true,
          ),
        ],
      ),
    ],
  );
}

/// The pine category colour, as stored.
const categoryColor = 0xFF0F5C4D;

void main() {
  widgetGolden('components_controls', _controls, height: 1300);
  widgetGolden('components_rows', _rows, height: 1000);
}
