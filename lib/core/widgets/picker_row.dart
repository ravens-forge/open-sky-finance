import 'package:flutter/material.dart';

/// A row of a [PickerSheet]
class PickerRow extends StatelessWidget {
  const PickerRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: ListTile(
        selected: selected,
        selectedTileColor: scheme.primaryContainer,
        selectedColor: scheme.onSurface,
        leading: leading,
        title: Text(
          title,
          style: selected ? const TextStyle(fontWeight: FontWeight.w600) : null,
        ),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: selected ? Icon(Icons.check, color: scheme.primary) : null,
        onTap: onTap,
      ),
    );
  }
}
