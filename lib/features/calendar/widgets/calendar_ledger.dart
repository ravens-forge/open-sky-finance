import 'package:flutter/material.dart';

import '../../../core/widgets/leader_row.dart';

/// A line of a tab's ledger: a bold heading, or an indented row under it.
class CalendarLedgerLine extends StatelessWidget {
  const CalendarLedgerLine({
    super.key,
    required this.name,
    required this.amount,
    this.heading = false,
  });

  final String name;
  final Widget amount;
  final bool heading;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsetsDirectional.only(start: heading ? 0 : 16),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: LeaderRow(name: name, amount: amount, bold: heading),
  );
}
