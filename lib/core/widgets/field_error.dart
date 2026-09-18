import 'package:flutter/material.dart';

import '../finance_colors.dart';

/// Message under an invalid value: circle-alert icon and 13 / 600 `expense`
/// text. Pass it as `InputDecoration.error`, or below a picker row.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final expense = FinanceColors.of(context).expense;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.error_outline, size: 16, color: expense),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: expense,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
