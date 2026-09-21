import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../finance_colors.dart';

enum _ChipKind { filled, outline, dashed, add, overdue }

class LedgerChip extends StatelessWidget {
  /// Label or favorite chip on `primaryContainer`. [trailingIcon] follows the
  /// text, e.g. the ✕ of a removable label.
  const LedgerChip.label(
    this.text, {
    super.key,
    this.icon,
    this.trailingIcon,
    this.compact = false,
    this.onPressed,
  }) : _kind = _ChipKind.filled;

  /// Outline chip, e.g. "+ Add" or "Automatic".
  const LedgerChip.outline(
    this.text, {
    super.key,
    this.icon,
    this.compact = false,
    this.onPressed,
  }) : _kind = _ChipKind.outline,
       trailingIcon = null;

  /// Dashed chip that adds something, e.g. "+ Add" under a list of labels.
  const LedgerChip.add(
    this.text, {
    super.key,
    this.icon,
    this.compact = false,
    this.onPressed,
  }) : _kind = _ChipKind.add,
       trailingIcon = null;

  /// Dashed italic chip for scheduled transactions.
  const LedgerChip.scheduled(this.text, {super.key, this.compact = true})
    : _kind = _ChipKind.dashed,
      icon = null,
      trailingIcon = null,
      onPressed = null;

  /// Overdue reminder chip on `secondaryContainer`.
  const LedgerChip.overdue(this.text, {super.key, this.compact = true})
    : _kind = _ChipKind.overdue,
      icon = null,
      trailingIcon = null,
      onPressed = null;

  final String text;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool compact;
  final VoidCallback? onPressed;
  final _ChipKind _kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final finance = FinanceColors.of(context);
    final (Color? fill, Color fg, Color? border) = switch (_kind) {
      _ChipKind.filled => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        null,
      ),
      _ChipKind.outline => (null, scheme.onSurface, scheme.outline),
      _ChipKind.dashed => (null, finance.muted, finance.disabled),
      _ChipKind.add => (null, scheme.onSurfaceVariant, finance.disabled),
      _ChipKind.overdue => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        null,
      ),
    };
    final style = theme.textTheme.bodySmall!.copyWith(
      color: fg,
      fontSize: compact ? 11 : 13,
      fontWeight: FontWeight.w500,
      fontStyle: _kind == _ChipKind.dashed ? FontStyle.italic : null,
    );

    final dashed = _kind == _ChipKind.dashed || _kind == _ChipKind.add;
    Widget chip = Container(
      constraints: BoxConstraints(minHeight: compact ? 20 : 30),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      decoration: dashed
          ? null
          : ShapeDecoration(
              color: fill,
              shape: StadiumBorder(
                side: border == null
                    ? BorderSide.none
                    : BorderSide(color: border),
              ),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 16, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(child: Text(text, style: style)),
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(trailingIcon, size: compact ? 12 : 14, color: fg),
          ],
        ],
      ),
    );
    if (dashed) {
      chip = CustomPaint(painter: _DashedStadium(border!), child: chip);
    }
    if (onPressed == null) return chip;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        // 48 px touch target around the visible pill.
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 14 : 9),
          child: chip,
        ),
      ),
    );
  }
}

class _DashedStadium extends CustomPainter {
  _DashedStadium(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    for (final PathMetric metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedStadium old) => old.color != color;
}
