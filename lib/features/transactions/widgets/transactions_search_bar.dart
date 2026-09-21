import 'package:flutter/material.dart';

import '../../../core/l10n.dart';

/// Search over titles and notes, and the button that opens the filters with
/// the number of active ones.
class TransactionsSearchBar extends StatelessWidget {
  const TransactionsSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.filterCount,
    required this.onFilters,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int filterCount;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder pill(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          borderSide: BorderSide(color: color, width: width),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.transactionsSearchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.actionClear,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      ),
                filled: true,
                fillColor: scheme.surfaceContainer,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: pill(scheme.outlineVariant),
                enabledBorder: pill(scheme.outlineVariant),
                focusedBorder: pill(scheme.primary, 2),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onFilters,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(
              filterCount == 0
                  ? l10n.transactionsFilters
                  : l10n.transactionsFiltersCount(filterCount),
            ),
          ),
        ],
      ),
    );
  }
}
