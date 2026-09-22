import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/labels.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../assets_accounts/models/assets_account_with_balance.dart';
import '../../assets_accounts/providers/assets_accounts_controller.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';

Future<void> showFavoriteAccountsSheet(BuildContext context) =>
    showPickerSheet<void>(context, (_) => const FavoriteAccountsSheet());

/// Checkboxes that star assets accounts for the Home charts, assets first.
/// Each change is saved at once.
class FavoriteAccountsSheet extends ConsumerWidget {
  const FavoriteAccountsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accounts = ref.watch(assetsAccountsWithBalanceProvider).value ?? [];
    final selected = accounts.where((a) => a.account.isFavorite).length;

    Widget eyebrow(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
      child: Text(text.toUpperCase(), style: theme.textTheme.eyebrow),
    );
    Widget row(AssetsAccountWithBalance item) {
      final a = item.account;
      final balance = formatMoney(
        item.balance.abs(),
        currency: a.currency,
        locale: l10n.localeName,
      );
      return CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        value: a.isFavorite,
        onChanged: (on) => ref
            .read(assetsAccountsControllerProvider.notifier)
            .setFavorite(a.id, on ?? false),
        title: Text(a.name, style: theme.textTheme.rowTitle),
        subtitle: Text(
          l10n.homeFavoriteSubtitle(
            a.type.label(l10n),
            item.balance < 0 ? '−$balance' : balance,
          ),
        ),
      );
    }

    final assets = accounts.where((a) => !a.account.type.isLiability);
    final liabilities = accounts.where((a) => a.account.type.isLiability);
    return PickerSheet(
      title: l10n.homeSectionFavoriteAccounts,
      header: Text(
        l10n.homeFavoritesIntro,
        style: theme.textTheme.bodyMedium!.copyWith(
          height: 1.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      footer: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            child: Text(l10n.homeFavoritesDone(selected)),
          ),
        ),
      ],
      children: [
        if (assets.isNotEmpty) eyebrow(l10n.assetsAccountsAssets),
        for (final a in assets) row(a),
        if (liabilities.isNotEmpty) eyebrow(l10n.assetsAccountsLiabilities),
        for (final a in liabilities) row(a),
      ],
    );
  }
}
