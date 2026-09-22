import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/ledger_dialog.dart';

Future<bool> showDeletePermanentlyDialog(
  BuildContext context, {
  int? count,
}) async {
  final l10n = context.l10n;
  final confirmed = await showLedgerDialog<bool>(
    context: context,
    kind: DialogKind.warning,
    title: count == null ? l10n.trashDeleteTitle : l10n.trashEmptyTitle,
    body: count == null
        ? l10n.assetsAccountDeleteNoUndo
        : '${l10n.trashEmptyBody(count)} ${l10n.assetsAccountDeleteNoUndo}',
    actions: [
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionCancel),
        ),
      ),
      Builder(
        builder: (context) => DestructiveButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            count == null ? l10n.trashDeletePermanently : l10n.trashEmpty,
          ),
        ),
      ),
    ],
  );
  return confirmed ?? false;
}
