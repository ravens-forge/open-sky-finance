import 'package:flutter/material.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.transparent = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: transparent ? null : scheme.surfaceContainer,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
