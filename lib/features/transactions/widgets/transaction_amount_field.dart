import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/currency_picker.dart';
import '../../../core/widgets/field_error.dart';

/// A large amount over an ink rule: the label in capitals, then the sign, the
/// currency symbol and the number in the colour of the type. Amounts are
/// always typed positive; [sign] shows what the type makes of them. The
/// smaller size is the amount received of a transfer.
class TransactionAmountField extends StatelessWidget {
  const TransactionAmountField({
    super.key,
    required this.controller,
    required this.label,
    required this.currency,
    required this.color,
    this.sign,
    this.large = true,
    this.autofocus = false,
    this.onChanged,
    this.error,
    this.helper,
  });

  final TextEditingController controller;
  final String label;
  final String currency;
  final Color color;

  /// `−`, `+` or `⇄`; left out for the amount received.
  final String? sign;
  final bool large;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final String? error;
  final Widget? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serif = theme.textTheme.hero.copyWith(color: color);
    return Container(
      padding: EdgeInsets.fromLTRB(0, large ? 22 : 14, 0, large ? 16 : 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(label.toUpperCase(), style: theme.textTheme.eyebrow),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 6,
            children: [
              if (sign != null)
                ExcludeSemantics(
                  child: Text(sign!, style: serif.copyWith(fontSize: 40)),
                ),
              Text(
                currencySymbol(currency),
                style: serif.copyWith(fontSize: large ? 32 : 26),
              ),
              Expanded(
                // The capitals above label it on screen; this says it aloud.
                child: Semantics(
                  label: label,
                  child: TextField(
                    controller: controller,
                    autofocus: autofocus,
                    onChanged: onChanged,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: serif.copyWith(fontSize: large ? 56 : 40),
                    cursorColor: color,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: serif.copyWith(
                        fontSize: large ? 56 : 40,
                        color: color.withValues(alpha: 0.35),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (error != null) FieldError(error!),
          ?helper,
        ],
      ),
    );
  }
}
