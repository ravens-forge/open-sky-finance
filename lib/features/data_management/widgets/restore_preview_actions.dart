import 'package:flutter/material.dart';

import '../../../core/l10n.dart';

/// The restore preview's bottom bar: Cancel and "Replace and restore".
class RestorePreviewActions extends StatelessWidget {
  const RestorePreviewActions({
    super.key,
    required this.onCancel,
    required this.onRestore,
  });

  final VoidCallback onCancel;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme.labelLarge!.copyWith(fontSize: 15);
    const size = Size(0, 52);
    const padding = EdgeInsets.symmetric(horizontal: 16);
    // Long translations wrap rather than shrink to an unreadable size.
    Widget label(String value) =>
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
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: size,
                    padding: padding,
                    textStyle: text,
                  ),
                  child: label(l10n.actionCancel),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: onRestore,
                  style: FilledButton.styleFrom(
                    minimumSize: size,
                    padding: padding,
                    textStyle: text,
                  ),
                  child: label(l10n.restoreAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
