import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/currency_picker.dart';

/// The monthly amount of one row of Edit budgets: the currency symbol where
/// the locale puts it and the number at the end; empty reads "No budget".
class BudgetAmountField extends StatelessWidget {
  const BudgetAmountField({
    super.key,
    required this.controller,
    required this.label,
    required this.currency,
    required this.onChanged,
    this.invalid = false,
  });

  final TextEditingController controller;

  /// Read aloud: the group or category the amount belongs to.
  final String label;
  final String currency;
  final ValueChanged<String> onChanged;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final scheme = theme.colorScheme;
    final filled = controller.text.trim().isNotEmpty;
    final style = theme.textTheme.bodyLarge!.copyWith(
      fontWeight: FontWeight.w600,
    );
    // `€1.00` in en, `1,00 €` in es and fr.
    final symbolAfter = RegExp(r'^\d').hasMatch(
      formatMoney(microsPerUnit, currency: currency, locale: l10n.localeName),
    );
    final symbol = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        currencySymbol(currency),
        style: style.copyWith(
          color: finance.muted,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
    final border = UnderlineInputBorder(
      borderSide: BorderSide(
        color: invalid
            ? finance.expense
            : filled
            ? scheme.outline
            : finance.disabled,
        width: filled || invalid ? 2 : 1,
      ),
    );

    // Grows to 130 % at most, and the field with it.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        width: MediaQuery.textScalerOf(context).scale(136).clamp(136, 177),
        child: Semantics(
          label: label,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.end,
            style: style,
            decoration: InputDecoration(
              hintText: l10n.budgetNone,
              hintStyle: style.copyWith(color: finance.muted),
              filled: filled,
              fillColor: scheme.surfaceContainer,
              enabledBorder: border,
              prefixIcon: symbolAfter ? null : symbol,
              suffixIcon: symbolAfter ? symbol : null,
              prefixIconConstraints: const BoxConstraints(),
              suffixIconConstraints: const BoxConstraints(),
              contentPadding: EdgeInsetsDirectional.only(
                start: symbolAfter ? 10 : 0,
                end: symbolAfter ? 0 : 10,
                top: 12,
                bottom: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
