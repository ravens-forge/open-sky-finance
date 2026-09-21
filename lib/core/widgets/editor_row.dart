import 'package:flutter/material.dart';

import '../finance_colors.dart';

/// A field of the transaction and reminder editors: an icon, a small label,
/// the value (or an inline input) and an optional helper line, over a
/// hairline. Tapping opens the field's picker when [onTap] is set.
class EditorRow extends StatelessWidget {
  const EditorRow({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.helper,
    this.helperColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final String? helper;

  /// `muted` when left out.
  final Color? helperColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = FinanceColors.of(context).muted;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          spacing: 14,
          children: [
            Icon(icon, size: 22, color: muted),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodyLarge!.copyWith(fontSize: 16),
                    child: child,
                  ),
                  if (helper != null)
                    Text(
                      helper!,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: helperColor ?? muted,
                      ),
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
