import 'package:flutter/material.dart';

import '../l10n.dart';

/// The mark (pine arc over two ink rules) without its background, drawn in the
/// theme's primary and ink so it follows light and dark.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.height});

  /// Drawer header.
  static const drawerHeight = 33.0;

  /// Onboarding Welcome.
  static const welcomeHeight = 48.0;

  /// Launch screen.
  static const launchHeight = 65.0;

  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: context.l10n.appTitle,
      child: CustomPaint(
        size: Size(height * _viewBox.width / _viewBox.height, height),
        painter: _LogoPainter(scheme.primary, scheme.onSurface),
      ),
    );
  }
}

// Crop of the 1254 × 1254 master to the shape.
const _viewBox = Rect.fromLTWH(266, 341, 722, 511);

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.arc, this.ink);

  final Color arc;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..scale(size.width / _viewBox.width)
      ..translate(-_viewBox.left, -_viewBox.top);
    final sky = Path()
      ..moveTo(326, 645)
      ..arcToPoint(
        const Offset(928, 645),
        radius: const Radius.elliptical(301, 304),
      )
      ..lineTo(872, 645)
      ..arcToPoint(
        const Offset(382, 645),
        radius: const Radius.elliptical(245, 248),
        clockwise: false,
      )
      ..close();
    final rules = Paint()..color = ink;
    canvas
      ..drawPath(sky, Paint()..color = arc)
      ..drawRect(const Rect.fromLTWH(266, 701, 722, 50), rules)
      ..drawRect(const Rect.fromLTWH(340, 802, 574, 50), rules);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.arc != arc || old.ink != ink;
}
