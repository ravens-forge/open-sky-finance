import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/main_currency.dart';
import '../../../app/routes.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/balance_chart.dart';
import '../models/home_section_place.dart';
import '../providers/home_controller.dart';
import '../providers/home_providers.dart';
import 'chart_empty_note.dart';
import 'chart_months_toggle.dart';
import 'home_section_frame.dart';

class NetWorthSection extends ConsumerWidget {
  const NetWorthSection({super.key, required this.place});

  final HomeSectionPlace place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final months = ref.watch(homeChartMonthsProvider).value ?? 6;
    final history = ref.watch(homeNetWorthProvider(months)).value;
    final currency = ref.watch(mainCurrencyProvider).value;
    return HomeSectionFrame(
      title: l10n.homeSectionNetWorth,
      place: place,
      caption: ChartMonthsToggle(months: months),
      child: switch ((history, currency)) {
        // A trend needs at least two months with something in them.
        (final history?, final currency?)
            when history.values.where((v) => v != 0).length > 1 =>
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              _Change(
                history.values.last - history.values.first,
                currency: currency,
                months: months,
              ),
              BalanceChart(
                history: history,
                currency: currency,
                describe: l10n.homeNetWorthSemantic,
                onMonthTap: (month) {
                  ref.read(homeControllerProvider.notifier).drillDown(month);
                  context.go(Routes.transactions);
                },
              ),
            ],
          ),
        (_?, _?) => ChartEmptyNote(l10n.homeNetWorthEmpty),
        _ => const SizedBox(height: 160),
      },
    );
  }
}

/// "+€7,030.15 in 6 months", in `income` or `expense`.
class _Change extends StatelessWidget {
  const _Change(this.micros, {required this.currency, required this.months});

  final int micros;
  final String currency;
  final int months;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finance = FinanceColors.of(context);
    final amount = formatMoney(
      micros.abs(),
      currency: currency,
      locale: l10n.localeName,
    );
    return Text(
      l10n.homeNetWorthChange(micros < 0 ? '−$amount' : '+$amount', months),
      style: Theme.of(context).textTheme.bodySmall!.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: micros < 0 ? finance.expense : finance.income,
      ),
    );
  }
}
