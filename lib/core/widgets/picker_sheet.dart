import 'package:flutter/material.dart';

import '../l10n.dart';

/// Opens a [PickerSheet] as a tall modal bottom sheet.
Future<T?> showPickerSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Above the shell's FAB, which would otherwise cover the footer.
      useRootNavigator: true,
      builder: (context) =>
          FractionallySizedBox(heightFactor: 0.9, child: builder(context)),
    );

class PickerSheet extends StatelessWidget {
  const PickerSheet({
    super.key,
    required this.title,
    required this.children,
    this.header,
    this.searchHint,
    this.onSearch,
    this.onSearchSubmitted,
    this.footer = const [],
  });

  final String title;
  final List<Widget> children;

  /// Between the title and the search field, e.g. the chosen items as chips.
  final Widget? header;

  /// Shows the search field when set (also its spoken label).
  final String? searchHint;
  final ValueChanged<String>? onSearch;

  /// The keyboard's action key, e.g. to create what was typed.
  final ValueChanged<String>? onSearchSubmitted;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.headlineSmall),
                ),
              ),
              IconButton(
                tooltip: context.l10n.actionClose,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
            child: header,
          ),
        if (searchHint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: TextField(
              onChanged: onSearch,
              onSubmitted: onSearchSubmitted,
              textInputAction: onSearchSubmitted == null
                  ? null
                  : TextInputAction.done,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: scheme.surface,
                isDense: true,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  borderSide: BorderSide(color: scheme.primary, width: 2),
                ),
              ),
            ),
          ),
        Expanded(child: ListView(children: children)),
        if (footer.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outline)),
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: footer,
            ),
          ),
      ],
    );
  }
}
