import 'package:flutter/material.dart';

import '../../../core/widgets/leader_row.dart';

class RestorePreviewRow extends StatelessWidget {
  const RestorePreviewRow(this.name, String this.value, {super.key})
    : amount = null;

  /// A money amount, e.g. an `AmountText`, in place of plain text.
  const RestorePreviewRow.amount(this.name, Widget this.amount, {super.key})
    : value = null;

  final String name;
  final String? value;
  final Widget? amount;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: LeaderRow(name: name, amount: amount ?? Text(value!)),
  );
}
