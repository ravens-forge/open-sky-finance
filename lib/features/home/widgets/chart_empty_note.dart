import 'package:flutter/material.dart';

class ChartEmptyNote extends StatelessWidget {
  const ChartEmptyNote(this.text, {super.key, this.action});

  final String text;

  /// E.g. "Set a budget".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = Text(
      text,
      style: theme.textTheme.bodyMedium!.copyWith(
        height: 1.5,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    if (action == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Center(child: message),
      );
    }
    return Row(
      spacing: 12,
      children: [
        Expanded(child: message),
        action!,
      ],
    );
  }
}
