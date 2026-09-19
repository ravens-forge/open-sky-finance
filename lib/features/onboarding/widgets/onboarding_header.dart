import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.label,
    required this.onSkip,
    this.step,
    this.total,
  });

  final String label;
  final VoidCallback onSkip;

  /// 1-based; progress is hidden without it ("What's new").
  final int? step;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label.toUpperCase(), style: theme.textTheme.eyebrow),
            ),
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(foregroundColor: scheme.primary),
              child: Text(l10n.actionSkip),
            ),
          ],
        ),
        if (step != null && total != null)
          Semantics(
            label: label,
            child: ExcludeSemantics(
              child: Row(
                spacing: 6,
                children: [
                  for (var i = 1; i <= total!; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        color: i <= step!
                            ? scheme.primary
                            : scheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
