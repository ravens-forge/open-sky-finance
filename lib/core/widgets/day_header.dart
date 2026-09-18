import 'package:flutter/material.dart';

class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          if (trailing != null)
            DefaultTextStyle.merge(
              style: theme.textTheme.bodySmall!.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
