import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../models/credit_usage.dart';

/// Thin square bar of the credit used against the limit.
class CreditUsageBar extends StatelessWidget {
  const CreditUsageBar(this.usage, {super.key});

  final CreditUsage usage;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LinearProgressIndicator(
        value: usage.fraction,
        minHeight: 4,
        color: FinanceColors.of(context).transfer,
        backgroundColor: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
