import 'package:flutter/material.dart';

/// The segmented pill every editor picks a type with: Assets / Liabilities,
/// Income / Expense, Income / Expense / Transfer. [locked] keeps the choice
/// visible with a lock instead of hiding it behind a disabled field.
class TypeSelector<T> extends StatelessWidget {
  const TypeSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.locked = false,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool locked;

  @override
  Widget build(BuildContext context) => SegmentedButton<T>(
    showSelectedIcon: false,
    segments: [
      for (final (value, label) in options)
        ButtonSegment(
          value: value,
          label: Text(label, overflow: TextOverflow.ellipsis),
          icon: locked && value == selected
              ? const Icon(Icons.lock_outline, size: 16)
              : null,
          enabled: !locked || value == selected,
        ),
    ],
    selected: {selected},
    onSelectionChanged: locked ? null : (s) => onChanged(s.first),
  );
}
