import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../data/models/label.dart';

Future<bool> showDeleteLabelDialog(
  BuildContext context, {
  required Label label,
  required int uses,
}) async {
  final l10n = context.l10n;
  final confirmed = await showLedgerDialog<bool>(
    context: context,
    kind: DialogKind.warning,
    title: l10n.labelDeleteTitle(label.name),
    body: '${l10n.labelDeleteBody(uses)} ${l10n.assetsAccountDeleteNoUndo}',
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
          child: Text(l10n.actionDelete),
        ),
      ),
    ],
  );
  return confirmed ?? false;
}
