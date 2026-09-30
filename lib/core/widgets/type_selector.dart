import 'package:flutter/material.dart';

import '../finance_colors.dart';
import 'glyph_text.dart';

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
  Widget build(BuildContext context) {
    final finance = FinanceColors.of(context);
    final ink = Theme.of(context).colorScheme.onSurface;
    // Locked labels stay readable: the choice in ink on sunken paper, the
    // other one muted.
    WidgetStateProperty<Color?> bySelection(Color? selected, Color? other) =>
        WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? selected : other,
        );
    return SegmentedButton<T>(
      showSelectedIcon: false,
      style: locked
          ? ButtonStyle(
              foregroundColor: bySelection(ink, finance.muted),
              iconColor: bySelection(ink, finance.muted),
              backgroundColor: bySelection(finance.sunken, null),
              side: WidgetStatePropertyAll(BorderSide(color: finance.disabled)),
            )
          : null,
      segments: [
        for (final (value, label) in options)
          ButtonSegment(
            value: value,
            // Long translations ("⇄ Transferencia") shrink rather than cut.
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: GlyphText(label, maxLines: 1),
            ),
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
}
