import 'package:flutter/material.dart';

import '../l10n.dart';
import 'category_avatar.dart';
import 'ledger_chip.dart';

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
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget amount;
  final List<String> labels;
  final bool scheduled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final chips = [
      if (scheduled) LedgerChip.scheduled(context.l10n.chipScheduled),
      for (final label in labels) LedgerChip.label(label, compact: true),
    ];
    return InkWell(
      onTap: onTap,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                      fontStyle: scheduled ? FontStyle.italic : null,
                    ),
                  ),
                  Text(subtitle, style: text.bodySmall),
                  if (chips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Wrap(spacing: 4, runSpacing: 4, children: chips),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DefaultTextStyle.merge(
              style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
              child: amount,
            ),
          ],
        ),
      ),
    );
  }
}
