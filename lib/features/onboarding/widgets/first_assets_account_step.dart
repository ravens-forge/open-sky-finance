import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../app/now.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/money/format_money.dart';
import '../../../core/money/parse_money.dart';
import '../../../core/result.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/currency_picker.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/field_row.dart';
import '../../../core/widgets/segmented_filter.dart';
import '../../../data/enums/assets_account_type.dart';
import '../../../data/models/assets_account_draft.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/repository_data_error.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_step_layout.dart';

/// Name, type, currency and current balance of the first assets account; its
/// currency becomes the default currency. "Skip for now" keeps the seeded Cash
/// assets account.
class FirstAssetsAccountStep extends HookConsumerWidget {
  const FirstAssetsAccountStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  static const _quickTypes = [
    AssetsAccountType.bank,
    AssetsAccountType.cash,
    AssetsAccountType.creditCard,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Zero in the locale and currency's format (0.00, 0,00, 0 for JPY).
    String zero(String currency) => formatMoney(
      0,
      currency: currency,
      locale: l10n.localeName,
      symbol: false,
    );
    // Suggested from the device region.
    final currency = useState(
      useMemoized(
        () => deviceCurrency(WidgetsBinding.instance.platformDispatcher.locale),
      ),
    );
    final name = useTextEditingController();
    final balance = useTextEditingController(text: zero(currency.value));
    final type = useState(AssetsAccountType.bank);
    final nameError = useState<String?>(null);
    final balanceError = useState<String?>(null);
    final saving = useState(false);

    Future<void> start() async {
      final trimmed = name.text.trim();
      final amount = balance.text.trim().isEmpty
          ? 0
          : parseMoney(balance.text, locale: l10n.localeName);
      nameError.value = trimmed.isEmpty ? l10n.errorNameRequired : null;
      balanceError.value = amount == null ? l10n.errorInvalidAmount : null;
      if (nameError.value != null || amount == null) return;

      saving.value = true;
      final result = await ref
          .read(onboardingProvider.notifier)
          .createFirstAssetsAccount(
            AssetsAccountDraft(
              name: trimmed,
              type: type.value,
              currency: currency.value,
              openingBalance: amount,
              openingBalanceDate: ref.read(todayProvider),
            ),
          );
      if (!context.mounted) return;
      saving.value = false;
      if (result case Err(:final error)) {
        if (error == RepositoryDataError.invalidName) {
          nameError.value = l10n.errorNameRequired;
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
        }
      }
    }

    Future<void> pickOtherType() async {
      final picked = await showChoiceSheet(
        context,
        title: l10n.fieldType,
        selected: type.value,
        options: [for (final t in AssetsAccountType.values) (t, t.label(l10n))],
      );
      if (picked != null) type.value = picked;
    }

    final symbol = currencySymbol(currency.value);

    return OnboardingStepLayout(
      actions: [
        OutlinedButton(
          onPressed: saving.value ? null : onSkip,
          child: Text(l10n.actionSkipForNow),
        ),
        FilledButton(
          onPressed: saving.value ? null : start,
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
          controller: name,
          textCapitalization: TextCapitalization.sentences,
          style: theme.textTheme.bodyLarge!.copyWith(fontSize: 18),
          decoration: InputDecoration(
            labelText: l10n.fieldName,
            error: nameError.value == null
                ? null
                : FieldError(nameError.value!),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.fieldType, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        SegmentedFilter<AssetsAccountType>(
          options: [
            for (final t in {..._quickTypes, type.value}) (t, t.label(l10n)),
          ],
          selected: type.value,
          onChanged: (t) => type.value = t,
          trailing: ActionChip(
            label: Text(l10n.actionOther),
            onPressed: pickOtherType,
          ),
        ),
        const SizedBox(height: 16),
        FieldRow(
          label: l10n.fieldCurrency,
          value: currencyLabel(currency.value, l10n),
          onTap: () async {
            final picked = await showCurrencyPicker(context, currency.value);
            if (picked == null) return;
            // Keep the default zero in the new currency's format.
            if (balance.text == zero(currency.value)) {
              balance.text = zero(picked);
            }
            currency.value = picked;
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
          controller: balance,
          // Tapping selects the default so typing replaces it.
          onTap: () => balance.selection = TextSelection(
            baseOffset: 0,
            extentOffset: balance.text.length,
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          style: theme.textTheme.displayMedium!.copyWith(fontSize: 34),
          decoration: InputDecoration(
            labelText: l10n.fieldCurrentBalance,
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
            error: balanceError.value == null
                ? null
                : FieldError(balanceError.value!),
          ),
        ),
      ],
    );
  }
}
