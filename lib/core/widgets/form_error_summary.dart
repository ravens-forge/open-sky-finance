import 'package:flutter/material.dart';

import '../finance_colors.dart';
import '../l10n.dart';
import 'note_block.dart';

class FormErrorSummary extends StatelessWidget {
  const FormErrorSummary({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final finance = FinanceColors.of(context);
    return NoteBlock(
      color: finance.expenseContainer,
      lead: context.l10n.formErrorSummary(count),
      text: context.l10n.formNothingSaved,
      icon: Icons.error_outline,
      iconColor: finance.expense,
      alert: true,
    );
  }
}
