import 'package:flutter/material.dart';

import '../finance_colors.dart';
import '../l10n.dart';
import 'category_avatar.dart';
import 'ledger_chip.dart';

class ReminderRow extends StatelessWidget {
  const ReminderRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.schedule,
    required this.due,
    required this.amount,
    this.overdue = false,
    this.onRecord,
    this.onSkip,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String schedule;
  final String due;
  final Widget amount;
  final bool overdue;
  final VoidCallback? onRecord;
  final VoidCallback? onSkip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final finance = FinanceColors.of(context);
    final automatic = onRecord == null && onSkip == null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryAvatar(icon: icon, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        title,
                        style: text.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.repeat, size: 14, color: finance.muted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(schedule, style: text.bodySmall),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            due,
                            style: text.bodySmall!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: overdue ? finance.warning : null,
                            ),
                          ),
                          if (automatic)
                            LedgerChip.outline(
                              l10n.chipAutomatic,
                              compact: true,
                            ),
                        ],
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
            if (!automatic)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 52, top: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: onRecord,
                      style: FilledButton.styleFrom(
                        minimumSize: _small,
                        padding: _smallPadding,
                        textStyle: _smallText,
                      ),
                      child: Text(l10n.reminderRecord),
                    ),
                    OutlinedButton(
                      onPressed: onSkip,
                      style: OutlinedButton.styleFrom(
                        minimumSize: _small,
                        padding: _smallPadding,
                        textStyle: _smallText,
                      ),
                      child: Text(l10n.reminderSkip),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 40 px row buttons; the padded tap target keeps them at 48 px.
const _small = Size(0, 40);
const _smallPadding = EdgeInsets.symmetric(horizontal: 16);
const _smallText = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
