import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../finance_colors.dart';
import 'large_text.dart';

class LeaderRow extends StatelessWidget {
  const LeaderRow({
    super.key,
    required this.name,
    required this.amount,
    this.onTap,
  });

  final String name;
  final Widget amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge!;
    final amountText = DefaultTextStyle.merge(
      style: style.copyWith(fontWeight: FontWeight.w600),
      child: amount,
    );
    if (isLargeText(context)) {
      // No room for a leader: the amount goes under the name.
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(name, style: style),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: amountText,
              ),
            ],
          ),
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            // The amount is laid out first and never shrinks; the name wraps
            // and the leader takes whatever is left.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final painter = TextPainter(
                    text: TextSpan(text: name, style: style),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout(maxWidth: math.max(0, constraints.maxWidth - 12));
                  final width = painter.width.ceilToDouble();
                  painter.dispose();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: width,
                        child: Text(name, style: style),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                          child: CustomPaint(
                            size: const Size(double.infinity, 2),
                            painter: _Leader(
                              FinanceColors.of(context).disabled,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            amountText,
          ],
        ),
      ),
    );
  }
}

class _Leader extends CustomPainter {
  _Leader(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawCircle(Offset(x + 1, size.height / 2), 1, paint);
    }
  }

  @override
  bool shouldRepaint(_Leader old) => old.color != color;
}
