import 'package:flutter/material.dart';

/// Square block with an optional icon and a bold [lead] before [text].
class NoteBlock extends StatelessWidget {
  const NoteBlock({
    super.key,
    required this.color,
    required this.text,
    this.lead,
    this.icon,
    this.iconColor,
    this.textColor,
    this.alert = false,
  });

  final Color color;
  final String text;
  final String? lead;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!
        .copyWith(color: textColor, height: 1.45);
    return Semantics(
      liveRegion: alert,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: color,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (lead != null)
                      TextSpan(
                        text: '$lead ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    TextSpan(text: text),
                  ],
                ),
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
