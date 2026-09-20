import 'package:flutter/material.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.transparent = false,
    this.background,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool transparent;

  /// A tint behind the icon; the neutral container colour when left out.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: transparent ? null : background ?? scheme.surfaceContainer,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
