import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Centered placeholder for a page or list with nothing to show.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.actions = const [],
  });

  final String title;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(32, 48, 32, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: CustomPaint(
              size: const Size(120, 64),
              painter: _LedgerPainter(theme.colorScheme),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

/// Two light rules, an ink baseline and the open-sky arc from the logo.
class _LedgerPainter extends CustomPainter {
  _LedgerPainter(this.colors);

  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()..color = colors.outlineVariant;
    canvas
      ..drawLine(const Offset(10, 20), const Offset(110, 20), rule)
      ..drawLine(const Offset(10, 36), const Offset(110, 36), rule)
      ..drawLine(
        const Offset(10, 52),
        const Offset(110, 52),
        Paint()
          ..color = colors.onSurface
          ..strokeWidth = 2,
      )
      ..drawArc(
        Rect.fromCircle(center: const Offset(60, 44), radius: 26),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = colors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_LedgerPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
