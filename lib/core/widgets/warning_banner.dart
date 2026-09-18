import 'package:flutter/material.dart';

import '../finance_colors.dart';
import 'note_block.dart';

class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key, required this.lead, required this.text});

  final String lead;
  final String text;

  @override
  Widget build(BuildContext context) {
    final finance = FinanceColors.of(context);
    return NoteBlock(
      color: finance.warningContainer,
      lead: lead,
      text: text,
      icon: Icons.warning_amber_rounded,
      iconColor: finance.warning,
    );
  }
}
