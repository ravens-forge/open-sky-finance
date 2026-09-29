import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/action_sheet.dart';
import '../../../data/models/transaction.dart';

/// Edit or Delete, offered on a long press on a transaction row.
Future<void> showTransactionOptionsSheet(
  BuildContext context,
  Transaction transaction, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  final l10n = context.l10n;
  return showActionSheet(
    context,
    title: transaction.title.isEmpty
        ? l10n.editorEditTransaction
        : transaction.title,
    actions: [
      SheetAction(Icons.edit_outlined, l10n.actionEdit, onEdit),
      SheetAction(Icons.delete_outline, l10n.actionDelete, onDelete),
    ],
  );
}
