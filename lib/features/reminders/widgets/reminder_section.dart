import 'package:flutter/material.dart';

import 'reminder_section_header.dart';

class ReminderSection extends StatelessWidget {
  const ReminderSection({
    super.key,
    required this.title,
    required this.rows,
    this.color,
    this.info,
  });

  final String title;
  final List<Widget> rows;
  final Color? color;
  final Widget? info;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReminderSectionHeader(
        title: title,
        color: color,
        info: info,
        caption: '${rows.length}',
      ),
      for (final (i, row) in rows.indexed) ...[if (i > 0) const Divider(), row],
    ],
  );
}
