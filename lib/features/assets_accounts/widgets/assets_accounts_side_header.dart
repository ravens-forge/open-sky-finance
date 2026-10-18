import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/currency_totals.dart';
import '../../../core/widgets/large_text.dart';

/// "Assets" or "Liabilities" with its subtotal, one line per currency.
class AssetsAccountsSideHeader extends StatelessWidget {
  const AssetsAccountsSideHeader({
    super.key,
    required this.title,
    required this.total,
  });

  final String title;

  /// Micro-units by currency.
  final Map<String, int> total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = Semantics(
      header: true,
      child: Text(title, style: theme.textTheme.sectionTitle),
    );
    final totals = CurrencyTotals(
      total,
      style: theme.textTheme.rowAmount.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.onSurface),
          ),
        ),
        // With large text the amounts go below, never broken inside.
        child: isLargeText(context)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: totals,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 12),
                  totals,
                ],
              ),
      ),
    );
  }
}
