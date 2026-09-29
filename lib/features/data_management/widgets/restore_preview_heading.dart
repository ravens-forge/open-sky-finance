import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';

class RestorePreviewHeading extends StatelessWidget {
  const RestorePreviewHeading(
    this.title, {
    super.key,
    this.caption,
    this.warning = false,
  });

  final String title;
  final String? caption;

  /// Draws [caption] as a warning, e.g. how many items are skipped.
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 22, bottom: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.onSurface)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: 12,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleLarge),
            ),
          ),
          if (caption != null)
            Text(
              caption!,
              style: warning
                  ? theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: FinanceColors.of(context).warning,
                    )
                  : theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
