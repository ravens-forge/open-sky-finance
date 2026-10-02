import 'package:flutter/material.dart';

/// A filled dot (a transaction type) or, with [ring], an outlined one (a
/// reminder due).
class CalendarMarker extends StatelessWidget {
  const CalendarMarker({
    super.key,
    required this.color,
    this.ring = false,
    this.size = 5,
  });

  final Color color;
  final bool ring;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: ring ? null : color,
      border: ring ? Border.all(color: color, width: 1.2) : null,
    ),
  );
}
