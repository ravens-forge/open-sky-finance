import 'package:flutter/material.dart';

import 'large_text.dart';

/// Buttons sharing a line equally; with large text they stack full width so
/// their labels never break inside a word.
class ButtonRow extends StatelessWidget {
  const ButtonRow({super.key, required this.children, this.spacing = 12});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => isLargeText(context)
      ? Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: spacing,
          children: children,
        )
      : Row(
          spacing: spacing,
          children: [for (final child in children) Expanded(child: child)],
        );
}
