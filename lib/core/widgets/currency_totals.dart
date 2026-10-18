import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/default_currency.dart';
import '../l10n.dart';
import '../money/currency_order.dart';
import '../money/format_money.dart';
import 'amount_text.dart';

/// One line per currency of [totals], end-aligned: the default currency
/// first, then by code, never converted. Past [foldedCurrencies] lines the
/// rest fold into "+N more currencies".
class CurrencyTotals extends HookConsumerWidget {
  const CurrencyTotals(
    this.totals, {
    super.key,
    this.amountStyle = AmountStyle.balance,
    this.style,
  });

  /// Micro-units by currency.
  final Map<String, int> totals;
  final AmountStyle amountStyle;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = useState(false);
    final fallback = ref.watch(defaultCurrencyProvider).value;
    if (fallback == null) return const SizedBox.shrink();
    final lines = totalsInOrder(totals, fallback);
    final shared = sharedSymbols(
      lines.map((l) => l.key),
      context.l10n.localeName,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final MapEntry(key: currency, value: micros)
            in expanded.value ? lines : lines.take(foldedCurrencies))
          AmountText(
            micros,
            currency: currency,
            amountStyle: amountStyle,
            style: style,
            code: shared.contains(currency),
          ),
        if (lines.length > foldedCurrencies)
          MoreCurrenciesButton(
            hidden: lines.length - foldedCurrencies,
            expanded: expanded.value,
            onPressed: () => expanded.value = !expanded.value,
          ),
      ],
    );
  }
}

/// "+N more currencies", or "Show fewer" once they are unfolded.
class MoreCurrenciesButton extends StatelessWidget {
  const MoreCurrenciesButton({
    super.key,
    required this.hidden,
    required this.expanded,
    required this.onPressed,
  });

  final int hidden;
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      expanded: expanded,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(48, 44),
          textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
        child: Text(
          expanded ? l10n.currenciesShowFewer : l10n.currenciesMore(hidden),
        ),
      ),
    );
  }
}
