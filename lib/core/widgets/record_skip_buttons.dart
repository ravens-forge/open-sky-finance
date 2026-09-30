import 'package:flutter/material.dart';

import '../l10n.dart';

/// "Record" (filled) and "Skip" (outline) of a reminder occurrence.
class RecordSkipButtons extends StatelessWidget {
  const RecordSkipButtons({
    super.key,
    required this.onRecord,
    required this.onSkip,
  });

  final VoidCallback? onRecord;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // From the theme, so the buttons keep the app's font.
    final text = Theme.of(context).textTheme.labelLarge!
        .copyWith(fontSize: 13, fontWeight: FontWeight.w600);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton(
          onPressed: onRecord,
          style: FilledButton.styleFrom(
            minimumSize: _small,
            padding: _smallPadding,
            textStyle: text,
          ),
          child: Text(l10n.reminderRecord),
        ),
        OutlinedButton(
          onPressed: onSkip,
          style: OutlinedButton.styleFrom(
            minimumSize: _small,
            padding: _smallPadding,
            textStyle: text,
          ),
          child: Text(l10n.reminderSkip),
        ),
      ],
    );
  }
}

// 40 px row buttons; the padded tap target keeps them at 48 px.
const _small = Size(0, 40);
const _smallPadding = EdgeInsets.symmetric(horizontal: 16);
