import 'package:flutter/material.dart';

/// Assets vs. liabilities as a share of their combined size: solid for
/// assets, diagonal hatching for liabilities.
class NetWorthProportionBar extends StatelessWidget {
  const NetWorthProportionBar({
    super.key,
    required this.assetsFraction,
    this.height = 12,
  });

  /// 0–1, the rest is liabilities.
  final double assetsFraction;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _ProportionPainter(
          assetsFraction: assetsFraction.clamp(0.0, 1.0),
          assetsColor: scheme.primary,
          liabilitiesColor: scheme.error,
          background: scheme.surface,
        ),
      ),
    );
  }
}

class _ProportionPainter extends CustomPainter {
  _ProportionPainter({
    required this.assetsFraction,
    required this.assetsColor,
    required this.liabilitiesColor,
    required this.background,
  });

  final double assetsFraction;
  final Color assetsColor;
  final Color liabilitiesColor;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final assetsWidth = w * assetsFraction;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, assetsWidth, h),
      Paint()..color = assetsColor,
    );
    if (assetsWidth >= w) return;

    final liabilitiesRect = Rect.fromLTWH(assetsWidth, 0, w - assetsWidth, h);
    canvas
      ..save()
      ..clipRect(liabilitiesRect)
      ..drawRect(liabilitiesRect, Paint()..color = background);
    final stripe = Paint()
      ..color = liabilitiesColor
      ..strokeWidth = 2;
    for (var x = liabilitiesRect.left - h; x < liabilitiesRect.right; x += 5) {
      canvas.drawLine(Offset(x, h), Offset(x + h, 0), stripe);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ProportionPainter old) =>
      old.assetsFraction != assetsFraction ||
      old.assetsColor != assetsColor ||
      old.liabilitiesColor != liabilitiesColor ||
      old.background != background;
}
