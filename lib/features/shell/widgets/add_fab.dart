import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../data/enums/transaction_type.dart';

/// Extended "+ Add" button that opens the transaction editor; the new
/// transaction starts on [date], today when `null`.
class AddFab extends StatelessWidget {
  const AddFab({super.key, this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () =>
          context.push(Routes.newTransaction(TransactionType.income, date)),
      icon: const Icon(Icons.add),
      label: Text(context.l10n.actionAdd),
    );
  }
}
