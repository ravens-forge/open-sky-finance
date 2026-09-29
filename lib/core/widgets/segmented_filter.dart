import 'package:flutter/material.dart';

class SegmentedFilter<T> extends StatelessWidget {
  const SegmentedFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.trailing,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: value == selected,
            onSelected: (_) => onChanged(value),
            selectedColor: scheme.onSurface,
            side: value == selected
                ? BorderSide(color: scheme.onSurface)
                : null,
            labelStyle: value == selected
                ? TextStyle(color: scheme.surface, fontWeight: FontWeight.w600)
                : TextStyle(color: scheme.onSurface),
          ),
        ?trailing,
      ],
    );
  }
}
