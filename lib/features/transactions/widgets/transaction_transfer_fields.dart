import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/editor_row.dart';
import '../../../core/widgets/field_error.dart';
import 'transaction_amount_field.dart';

/// From and To assets accounts with the round swap button between them and,
/// when the currencies differ, the amount received with the rate under it:
/// typing the amount fills the rate, and tapping the rate edits it.
class TransactionTransferFields extends StatelessWidget {
  const TransactionTransferFields({
    super.key,
    required this.fromValue,
    required this.toValue,
    required this.onFrom,
    required this.onTo,
    required this.onSwap,
    required this.fromCurrency,
    required this.toCurrency,
    required this.received,
    required this.onReceived,
    required this.rate,
    required this.onEditRate,
    required this.destinationError,
    required this.receivedError,
  });

  final String fromValue;
  final String toValue;
  final VoidCallback onFrom;
  final VoidCallback onTo;
  final VoidCallback onSwap;
  final String fromCurrency;

  /// `null` until a destination is chosen; the amount received shows only
  /// when it differs from [fromCurrency].
  final String? toCurrency;
  final TextEditingController received;
  final ValueChanged<String> onReceived;

  /// Units of [toCurrency] per unit of [fromCurrency], as typed or computed;
  /// empty until known.
  final String rate;
  final VoidCallback onEditRate;
  final String? destinationError;
  final String? receivedError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final transfer = FinanceColors.of(context).transfer;
    final crossCurrency = toCurrency != null && toCurrency != fromCurrency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Column(
              children: [
                EditorRow(
                  icon: Icons.call_made,
                  label: l10n.fieldFrom,
                  onTap: onFrom,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 52),
                    child: Text(fromValue),
                  ),
                ),
                EditorRow(
                  icon: Icons.call_received,
                  label: l10n.fieldTo,
                  onTap: onTo,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 52),
                    child: Text(toValue),
                  ),
                ),
              ],
            ),
            PositionedDirectional(
              end: 0,
              top: 38,
              child: IconButton(
                tooltip: l10n.actionSwap,
                onPressed: onSwap,
                icon: const Icon(Icons.swap_vert),
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(44),
                  backgroundColor: scheme.surfaceContainer,
                  foregroundColor: scheme.onSurface,
                  side: BorderSide(color: scheme.outline),
                ),
              ),
            ),
          ],
        ),
        if (destinationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FieldError(destinationError!),
          ),
        if (crossCurrency)
          TransactionAmountField(
            controller: received,
            label: l10n.fieldAmountReceivedIn(toCurrency!),
            currency: toCurrency!,
            color: transfer,
            large: false,
            onChanged: onReceived,
            error: receivedError,
            helper: Text.rich(
              TextSpan(
                text: l10n.transactionRateNote,
                children: [
                  const TextSpan(text: ' · '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: InkWell(
                      onTap: onEditRate,
                      child: Text(
                        l10n.transactionRate(
                          fromCurrency,
                          rate.isEmpty ? '?' : rate,
                          toCurrency!,
                        ),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
