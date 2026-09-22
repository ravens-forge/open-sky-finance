import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/ledger_chip.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../models/home_section_place.dart';
import 'chart_empty_note.dart';
import 'favorite_accounts_sheet.dart';
import 'home_section_frame.dart';
import 'section_link.dart';

class FavoriteAccountsSection extends ConsumerWidget {
  const FavoriteAccountsSection({super.key, required this.place});

  final HomeSectionPlace place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accounts = ref.watch(assetsAccountsProvider).value;
    final favorites = [...?accounts?.where((a) => a.isFavorite)];
    return HomeSectionFrame(
      title: l10n.homeSectionFavoriteAccounts,
      place: place,
      eyebrow: true,
      caption: favorites.isEmpty
          ? null
          : SectionLink(
              l10n.actionEdit,
              onPressed: () => showFavoriteAccountsSheet(context),
            ),
      child: accounts == null
          ? const SizedBox(height: 30)
          : favorites.isEmpty
          ? ChartEmptyNote(
              l10n.homeFavoritesEmpty,
              action: OutlinedButton(
                onPressed: () => showFavoriteAccountsSheet(context),
                child: Text(l10n.homeFavoritesChoose),
              ),
            )
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in favorites)
                  LedgerChip.label(a.name, icon: Icons.star),
              ],
            ),
    );
  }
}
