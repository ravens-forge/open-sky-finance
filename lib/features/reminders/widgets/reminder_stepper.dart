import 'package:flutter/material.dart';

import '../../../core/l10n.dart';

/// A count between round − and + buttons ("2 months", "12 times"), under an
/// optional small [label]. [onFewer] `null` at the minimum.
class ReminderStepper extends StatelessWidget {
  const ReminderStepper({
    super.key,
    this.label,
    required this.value,
    required this.onFewer,
    required this.onMore,
  });

  final String? label;
  final String value;
  final VoidCallback? onFewer;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget button(IconData icon, String tooltip, VoidCallback? onPressed) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(44),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        if (label != null) Text(label!, style: theme.textTheme.bodySmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(Icons.remove, l10n.reminderStepperFewer, onFewer),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 60),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            button(Icons.add, l10n.reminderStepperMore, onMore),
          ],
        ),
      ],
    );
  }
}
