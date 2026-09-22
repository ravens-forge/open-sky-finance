import 'package:flutter/material.dart';

import '../../../core/widgets/leader_row.dart';

class RestorePreviewRow extends StatelessWidget {
  const RestorePreviewRow(this.name, this.value, {super.key});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: LeaderRow(name: name, amount: Text(value)),
  );
}
