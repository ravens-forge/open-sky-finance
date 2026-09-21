import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';

/// The editor's bottom bar: "Save and add another" and Save for a new
/// transaction, Delete (to the Trash) and "Save changes" for an existing one.
class TransactionFormActions extends StatelessWidget {
  const TransactionFormActions({
    super.key,
    required this.saving,
    required this.onSave,
    this.onSaveAndAddAnother,
    this.onDelete,
  });

  final bool saving;
  final VoidCallback onSave;

  /// New transactions only.
  final VoidCallback? onSaveAndAddAnother;

  /// Existing transactions only.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final expense = FinanceColors.of(context).expense;
    final text = theme.textTheme.labelLarge!.copyWith(fontSize: 15);
    const size = Size(0, 52);
    const padding = EdgeInsets.symmetric(horizontal: 16);
    Widget label(String value) =>
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, maxLines: 1));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Row(
            spacing: 10,
            children: [
              if (onDelete != null)
                OutlinedButton.icon(
                  onPressed: saving ? null : onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.actionDelete),
                  style: OutlinedButton.styleFrom(
                    minimumSize: size,
                    padding: padding,
                    textStyle: text.copyWith(fontWeight: FontWeight.w700),
                    foregroundColor: expense,
                    side: BorderSide(color: expense),
                  ),
                ),
              if (onSaveAndAddAnother != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : onSaveAndAddAnother,
                    style: OutlinedButton.styleFrom(
                      minimumSize: size,
                      padding: padding,
                      textStyle: text,
                    ),
                    child: label(l10n.actionSaveAndAddAnother),
                  ),
                ),
              Expanded(
                child: FilledButton(
                  onPressed: saving ? null : onSave,
                  style: FilledButton.styleFrom(
                    minimumSize: size,
                    padding: padding,
                    textStyle: text,
                  ),
                  child: label(
                    onDelete == null ? l10n.actionSave : l10n.actionSaveChanges,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
