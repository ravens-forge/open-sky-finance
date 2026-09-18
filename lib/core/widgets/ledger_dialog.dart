import 'package:flutter/material.dart';

import '../finance_colors.dart';

enum DialogKind { confirm, warning, error }

Future<T?> showLedgerDialog<T>({
  required BuildContext context,
  required String title,
  required String body,
  required List<Widget> actions,
  DialogKind kind = DialogKind.confirm,
  Widget? extra,
}) => showDialog<T>(
  context: context,
  builder: (context) => LedgerDialog(
    title: title,
    body: body,
    actions: actions,
    kind: kind,
    extra: extra,
  ),
);

class LedgerDialog extends StatelessWidget {
  const LedgerDialog({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.kind = DialogKind.confirm,
    this.extra,
  });

  final String title;
  final String body;
  final List<Widget> actions;
  final DialogKind kind;

  /// Shown below [body], e.g. a file name or radio rows.
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final finance = FinanceColors.of(context);
    final icon = switch (kind) {
      DialogKind.confirm => null,
      DialogKind.warning => (
        Icons.warning_amber_rounded,
        finance.warning,
        finance.warningContainer,
      ),
      DialogKind.error => (
        Icons.error_outline,
        finance.expense,
        finance.expenseContainer,
      ),
    };
    return AlertDialog(
      scrollable: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon case (final data, final color, final tint)) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(data, size: 22, color: color),
            ),
            const SizedBox(height: 14),
          ],
          Text(title),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body),
          if (extra != null) ...[const SizedBox(height: 12), extra!],
        ],
      ),
      actions: actions,
    );
  }
}
