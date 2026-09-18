import 'package:flutter/material.dart';

class SegmentedFilter<T> extends StatelessWidget {
  const SegmentedFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final (value, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: value == selected,
            onSelected: (_) => onChanged(value),
            selectedColor: scheme.onSurface,
            labelStyle: TextStyle(
              color: value == selected ? scheme.surface : scheme.onSurface,
            ),
          ),
      ],
    );
  }
}
