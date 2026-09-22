import 'package:flutter/material.dart';

/// An underlined text link, like "Edit" or "Details", in ink unless [color].
class SectionLink extends StatelessWidget {
  const SectionLink(
    this.text, {
    super.key,
    required this.onPressed,
    this.color,
  });

  final String text;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? theme.colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(48, 44),
        textStyle: theme.textTheme.labelLarge!.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
      child: Text(text),
    );
  }
}
