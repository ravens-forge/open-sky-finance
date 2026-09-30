import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class ReminderSectionHeader extends StatelessWidget {
  const ReminderSectionHeader({
    super.key,
    required this.title,
    this.color,
    this.info,
    this.caption,
  });

  final String title;

  /// `warning` for the overdue section; the muted heading colour otherwise.
  final Color? color;
  final Widget? info;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      // The info icon brings its own 48 px: the heading text stays where it
      // is on the other headings.
      padding: info == null
          ? const EdgeInsets.only(top: 18, bottom: 6)
          : const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title.toUpperCase(),
                      style: theme.textTheme.eyebrow.copyWith(color: color),
                    ),
                  ),
                ),
                ?info,
              ],
            ),
          ),
          if (caption != null) Text(caption!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
