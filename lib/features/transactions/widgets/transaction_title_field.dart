import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/editor_row.dart';
import '../../../data/models/title_suggestion.dart';
import '../providers/transactions_controller.dart';

/// Title with autocomplete over previous titles; choosing one hands the
/// caller its latest use, to pre-fill the category and assets accounts, and
/// [suggested] then says what it brought.
class TransactionTitleField extends ConsumerStatefulWidget {
  const TransactionTitleField({
    super.key,
    required this.controller,
    required this.onSuggestion,
    this.suggested,
  });

  final TextEditingController controller;
  final ValueChanged<TitleSuggestion> onSuggestion;

  /// "Groceries · Wallet" once a suggestion was chosen.
  final String? suggested;

  @override
  ConsumerState<TransactionTitleField> createState() =>
      _TransactionTitleFieldState();
}

class _TransactionTitleFieldState extends ConsumerState<TransactionTitleField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final autocomplete = RawAutocomplete<TitleSuggestion>(
      textEditingController: widget.controller,
      focusNode: _focus,
      displayStringForOption: (suggestion) => suggestion.title,
      optionsBuilder: (value) async {
        final prefix = value.text.trim();
        if (prefix.isEmpty) return const <TitleSuggestion>[];
        return ref
            .read(transactionsControllerProvider.notifier)
            .titleSuggestions(prefix);
      },
      onSelected: widget.onSuggestion,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) =>
          TextField(
            controller: controller,
            focusNode: focusNode,
            onSubmitted: (_) => onFieldSubmitted(),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.fieldTitleHint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: AlignmentDirectional.topStart,
        child: Material(
          elevation: 2,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final suggestion in options)
                  ListTile(
                    title: Text(suggestion.title),
                    onTap: () => onSelected(suggestion),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return EditorRow(
      icon: Icons.article_outlined,
      label: l10n.fieldTitle,
      helper: widget.suggested == null
          ? null
          : l10n.transactionSuggested(widget.suggested!),
      helperColor: Theme.of(context).colorScheme.primary,
      child: autocomplete,
    );
  }
}
