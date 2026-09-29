import 'package:flutter/material.dart';

import '../../../core/l10n.dart';

class ReportBugActions extends StatelessWidget {
  const ReportBugActions({
    super.key,
    required this.onCopy,
    required this.onOpen,
  });

  final VoidCallback? onCopy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme.labelLarge!.copyWith(fontSize: 15);
    const size = Size(0, 52);
    const padding = EdgeInsets.symmetric(horizontal: 16);
    // Long translations wrap rather than shrink to an unreadable size.
    Widget wrapped(String value) =>
        Text(value, maxLines: 2, textAlign: TextAlign.center);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Row(
            spacing: 10,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCopy,
                  style: OutlinedButton.styleFrom(
                    minimumSize: size,
                    padding: padding,
                    textStyle: text,
                  ),
                  child: wrapped(l10n.reportBugCopy),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    minimumSize: size,
                    padding: padding,
                    textStyle: text,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Flexible(child: wrapped(l10n.reportBugOpen)),
                      const Icon(Icons.open_in_new, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
