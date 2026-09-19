import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/money/parse_money.dart';
import '../../../core/result.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/currency_picker.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/field_row.dart';
import '../../../data/enums/assets_account_type.dart';
import '../../../data/models/assets_account_draft.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/repository_data_error.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_step_layout.dart';

/// Name, type, currency and current balance of the first assets account; its
/// currency becomes the main currency. "Skip for now" keeps the seeded Cash
/// assets account.
class FirstAssetsAccountStep extends ConsumerStatefulWidget {
  const FirstAssetsAccountStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  ConsumerState<FirstAssetsAccountStep> createState() =>
      _FirstAssetsAccountStepState();
}

class _FirstAssetsAccountStepState
    extends ConsumerState<FirstAssetsAccountStep> {
  static const _quickTypes = [
    AssetsAccountType.bank,
    AssetsAccountType.cash,
    AssetsAccountType.creditCard,
  ];

  final _name = TextEditingController();
  final _balance = TextEditingController();
  var _type = AssetsAccountType.bank;
  // Suggested from the device region.
  late var _currency = deviceCurrency(
    WidgetsBinding.instance.platformDispatcher.locale,
  );
  String? _nameError;
  String? _balanceError;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    final balance = _balance.text.trim().isEmpty
        ? 0
        : parseMoney(_balance.text, locale: l10n.localeName);
    setState(() {
      _nameError = name.isEmpty ? l10n.errorNameRequired : null;
      _balanceError = balance == null ? l10n.errorInvalidAmount : null;
    });
    if (_nameError != null || balance == null) return;

    setState(() => _saving = true);
    final result = await ref
        .read(onboardingProvider.notifier)
        .createFirstAssetsAccount(
          AssetsAccountDraft(
            name: name,
            type: _type,
            currency: _currency,
            openingBalance: balance,
            openingBalanceDate: startOfDay(DateTime.now()),
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result case Err(:final error)) {
      if (error == RepositoryDataError.invalidName) {
        setState(() => _nameError = l10n.errorNameRequired);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
      }
    }
  }

  Future<void> _pickOtherType() async {
    final l10n = context.l10n;
    final picked = await showChoiceSheet(
      context,
      title: l10n.fieldType,
      selected: _type,
      options: [for (final t in AssetsAccountType.values) (t, t.label(l10n))],
    );
    if (picked != null) setState(() => _type = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final symbol = currencySymbol(_currency);

    return OnboardingStepLayout(
      actions: [
        OutlinedButton(
          onPressed: _saving ? null : widget.onSkip,
          child: Text(l10n.actionSkipForNow),
        ),
        FilledButton(
          onPressed: _saving ? null : _start,
          child: Text(l10n.actionStart),
        ),
      ],
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.firstAssetsAccountTitle,
            style: theme.textTheme.displayMedium!.copyWith(fontSize: 36),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.firstAssetsAccountIntro,
          style: theme.textTheme.bodyLarge!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          style: theme.textTheme.bodyLarge!.copyWith(fontSize: 18),
          decoration: InputDecoration(
            labelText: l10n.fieldName,
            error: _nameError == null ? null : FieldError(_nameError!),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.fieldType, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in {..._quickTypes, _type})
              ChoiceChip(
                label: Text(t.label(l10n)),
                selected: t == _type,
                selectedColor: theme.colorScheme.onSurface,
                labelStyle: t == _type
                    ? TextStyle(
                        color: theme.colorScheme.surface,
                        fontWeight: FontWeight.w600,
                      )
                    : null,
                onSelected: (_) => setState(() => _type = t),
              ),
            ActionChip(
              label: Text(l10n.actionOther),
              onPressed: _pickOtherType,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FieldRow(
          label: l10n.fieldCurrency,
          value: currencyLabel(_currency, l10n),
          onTap: () async {
            final picked = await showCurrencyPicker(context, _currency);
            if (picked != null) setState(() => _currency = picked);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            l10n.firstAssetsAccountCurrencyNote,
            style: theme.textTheme.bodySmall,
          ),
        ),
        TextField(
          controller: _balance,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          style: theme.textTheme.displayMedium!.copyWith(fontSize: 34),
          decoration: InputDecoration(
            labelText: l10n.fieldCurrentBalance,
            hintText: '0',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            // prefixIcon, unlike prefixText, shows while the field is empty.
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Text(
                symbol,
                style: theme.textTheme.displayMedium!.copyWith(fontSize: 28),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
            error: _balanceError == null ? null : FieldError(_balanceError!),
          ),
        ),
      ],
    );
  }
}
