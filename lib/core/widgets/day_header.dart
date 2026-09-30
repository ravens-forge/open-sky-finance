import 'package:flutter/material.dart';

import 'large_text.dart';

class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = trailing == null
        ? null
        : DefaultTextStyle.merge(
            style: theme.textTheme.bodySmall!.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            child: trailing!,
          );
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: isLargeText(context) && trailing != null
          // No room side by side: the total goes under the day.
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Align(alignment: AlignmentDirectional.centerEnd, child: total),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                ?total,
              ],
            ),
    );
  }
}
