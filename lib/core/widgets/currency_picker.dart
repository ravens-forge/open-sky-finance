import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n.dart';
import '../money/currencies.dart';
import 'picker_row.dart';
import 'picker_sheet.dart';

/// `EUR · Euro`, or just the code when its name is not translated.
String currencyLabel(String code, AppLocalizations l10n) {
  final name = l10n.currencyName(code);
  return name == code ? code : '$code · $name';
}

/// `€` for EUR, the code when there is no short symbol.
String currencySymbol(String code) =>
    NumberFormat.simpleCurrency(name: code).currencySymbol;

/// Lets the user pick an ISO 4217 code; `null` when dismissed.
Future<String?> showCurrencyPicker(BuildContext context, String selected) =>
    showPickerSheet<String>(
      context,
      (context) => _CurrencyPicker(selected: selected),
    );

class _CurrencyPicker extends StatefulWidget {
  const _CurrencyPicker({required this.selected});

  final String selected;

  @override
  State<_CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<_CurrencyPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = _query.trim().toLowerCase();
    final codes = [
      widget.selected,
      ...isoCurrencies.where((c) => c != widget.selected),
    ].where((c) => currencyLabel(c, l10n).toLowerCase().contains(query));
    return PickerSheet(
      title: l10n.fieldCurrency,
      searchHint: l10n.currencySearch,
      onSearch: (value) => setState(() => _query = value),
      children: [
        for (final code in codes)
          PickerRow(
            title: currencyLabel(code, l10n),
            leading: SizedBox(
              width: 40,
              child: Text(currencySymbol(code), textAlign: TextAlign.center),
            ),
            selected: code == widget.selected,
            onTap: () => Navigator.pop(context, code),
          ),
      ],
    );
  }
}
