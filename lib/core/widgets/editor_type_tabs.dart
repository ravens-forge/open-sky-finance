import 'package:flutter/material.dart';

import '../finance_colors.dart';

/// Tabs of the transaction editor; the active tab is underlined
/// in its own semantic colour.
class EditorTypeTabs<T> extends StatelessWidget {
  const EditorTypeTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String, Color)> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = FinanceColors.of(context).muted;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          for (final (value, label, color) in tabs)
            Expanded(
              child: Semantics(
                selected: value == selected,
                inMutuallyExclusiveGroup: true,
                child: InkWell(
                  onTap: () => onChanged(value),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: value == selected
                        ? BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: color, width: 3),
                            ),
                          )
                        : null,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall!.copyWith(
                        fontSize: 15,
                        color: value == selected
                            ? theme.colorScheme.onSurface
                            : muted,
                        fontWeight: value == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
