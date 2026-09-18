import 'package:flutter/material.dart';

import '../finance_colors.dart';

class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final expense = FinanceColors.of(context).expense;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: expense,
        side: BorderSide(color: expense),
      ),
      child: child,
    );
  }
}
