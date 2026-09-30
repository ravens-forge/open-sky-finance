import 'package:flutter/material.dart';

import '../l10n.dart';
import 'category_avatar.dart';
import 'ledger_chip.dart';
import 'trailing_amount.dart';
import 'glyph_text.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.labels = const [],
    this.scheduled = false,
    this.struckThrough = false,
    this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget amount;
  final List<String> labels;
  final bool scheduled;
  final bool struckThrough;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final chips = [
      if (scheduled) LedgerChip.scheduled(context.l10n.chipScheduled),
      for (final label in labels) LedgerChip.label(label, compact: true),
    ];
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            CategoryAvatar(
              icon: icon,
              color: iconColor,
              transparent: scheduled,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TrailingAmount(
                text: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w500,
                        fontStyle: scheduled ? FontStyle.italic : null,
                        decoration: struckThrough
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    GlyphText(subtitle, style: text.bodySmall),
                    if (chips.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Wrap(spacing: 4, runSpacing: 4, children: chips),
                      ),
                  ],
                ),
                amount: DefaultTextStyle.merge(
                  style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
                  child: amount,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
