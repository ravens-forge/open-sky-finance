import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';

/// "This is a refund (adds to the assets account)" with its checkbox: an
/// expense that brings money back.
class TransactionRefundRow extends StatelessWidget {
  const TransactionRefundRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        value: value,
        onChanged: (on) => onChanged(on ?? false),
        title: Text.rich(
          TextSpan(
            text: l10n.transactionRefund,
            children: [
              const TextSpan(text: ' '),
              TextSpan(
                text: l10n.transactionRefundNote,
                style: TextStyle(color: FinanceColors.of(context).muted),
              ),
            ],
          ),
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}
