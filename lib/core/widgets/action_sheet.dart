import 'package:flutter/material.dart';

import '../finance_colors.dart';
import 'picker_row.dart';
import 'picker_sheet.dart';

class SheetAction {
  const SheetAction(this.icon, this.label, this.onSelected);

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
}

Future<void> showActionSheet(
  BuildContext context, {
  required String title,
  required List<SheetAction> actions,
}) async {
  final chosen = await showPickerSheet<SheetAction>(context, (context) {
    final muted = FinanceColors.of(context).muted;
    return PickerSheet(
      title: title,
      children: [
        for (final action in actions)
          PickerRow(
            leading: Icon(action.icon, color: muted),
            title: action.label,
            onTap: () => Navigator.pop(context, action),
          ),
      ],
    );
  });
  chosen?.onSelected();
}
