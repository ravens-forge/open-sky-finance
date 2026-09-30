import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/trailing_amount.dart';
import '../../../data/enums/category_kind.dart';
import 'budget_amount_field.dart';

class EditBudgetRow extends StatelessWidget {
  const EditBudgetRow({
    super.key,
    required this.name,
    required this.note,
    required this.isGroup,
    required this.controller,
    required this.currency,
    required this.onChanged,
    this.invalid = false,
  });

  final String name;

  /// What was spent, or "Covered by the group budget".
  final String note;
  final bool isGroup;
  final TextEditingController controller;
  final String currency;
  final ValueChanged<String> onChanged;

  /// The amount typed cannot be read, or is not above zero.
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: BoxConstraints(minHeight: isGroup ? 60 : 56),
      margin: EdgeInsets.only(top: isGroup ? 14 : 0),
      padding: EdgeInsetsDirectional.only(
        start: isGroup ? 0 : 22,
        top: isGroup ? 8 : 6,
        bottom: isGroup ? 8 : 6,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isGroup ? scheme.outline : scheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isGroup) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CategoryKind.expense.color(context),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TrailingAmount(
              text: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: isGroup
                        ? theme.textTheme.bodyLarge!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          )
                        : theme.textTheme.bodyLarge,
                  ),
                  invalid
                      ? FieldError(context.l10n.budgetAmountInvalid)
                      : Text(note, style: theme.textTheme.bodySmall),
                ],
              ),
              amount: BudgetAmountField(
                controller: controller,
                label: name,
                currency: currency,
                onChanged: onChanged,
                invalid: invalid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
