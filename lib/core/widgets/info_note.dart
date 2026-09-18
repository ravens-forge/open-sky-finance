import 'package:flutter/material.dart';

import '../finance_colors.dart';
import 'note_block.dart';

class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final finance = FinanceColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return NoteBlock(
      color: finance.sunken,
      text: text,
      icon: icon,
      iconColor: finance.muted,
      textColor: scheme.onSurfaceVariant,
    );
  }
}
