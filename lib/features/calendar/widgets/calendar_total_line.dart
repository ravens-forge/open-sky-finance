import 'package:flutter/material.dart';

/// The bottom line of a tab under a heavy ink rule: net income or net worth,
/// then an optional [note] and a [link] to the full page.
class CalendarTotalLine extends StatelessWidget {
  const CalendarTotalLine({
    super.key,
    required this.label,
    required this.amount,
    required this.link,
    this.note,
  });

  final String label;
  final Widget amount;
  final Widget link;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.onSurface, width: 3),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              DefaultTextStyle.merge(
                style: theme.textTheme.headlineSmall,
                child: amount,
              ),
            ],
          ),
        ),
        if (note != null)
          Text(
            note!,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall,
          ),
        Align(alignment: AlignmentDirectional.centerStart, child: link),
      ],
    );
  }
}
