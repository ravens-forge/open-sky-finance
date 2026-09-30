import 'package:flutter/material.dart';

import 'large_text.dart';

/// [text] with [amount] at its end. With large text the amount drops below,
/// end-aligned, so neither is squeezed into broken words.
class TrailingAmount extends StatelessWidget {
  const TrailingAmount({
    super.key,
    required this.text,
    required this.amount,
    this.gap = 12,
  });

  final Widget text;
  final Widget amount;
  final double gap;

  @override
  Widget build(BuildContext context) => isLargeText(context)
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            text,
            Align(alignment: AlignmentDirectional.centerEnd, child: amount),
          ],
        )
      : Row(
          children: [
            Expanded(child: text),
            SizedBox(width: gap),
            amount,
          ],
        );
}
