import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';

/// OPTIONS: favorite, exclude from net worth, hidden.
class AssetsAccountOptions extends StatelessWidget {
  const AssetsAccountOptions({
    super.key,
    required this.isFavorite,
    required this.excludeFromNetWorth,
    required this.isHidden,
    required this.onFavorite,
    required this.onExcludeFromNetWorth,
    required this.onHidden,
  });

  final bool isFavorite;
  final bool excludeFromNetWorth;
  final bool isHidden;
  final ValueChanged<bool> onFavorite;
  final ValueChanged<bool> onExcludeFromNetWorth;
  final ValueChanged<bool> onHidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget option(
      String title,
      String note,
      bool value,
      ValueChanged<bool> onChanged,
    ) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(note),
      value: value,
      onChanged: onChanged,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.assetsAccountOptions.toUpperCase(),
          style: Theme.of(context).textTheme.eyebrow,
        ),
        option(
          l10n.assetsAccountFavoriteOption,
          l10n.assetsAccountFavoriteOptionNote,
          isFavorite,
          onFavorite,
        ),
        option(
          l10n.assetsAccountExcludeOption,
          l10n.assetsAccountExcludeOptionNote,
          excludeFromNetWorth,
          onExcludeFromNetWorth,
        ),
        option(
          l10n.assetsAccountHidden,
          l10n.assetsAccountHiddenOptionNote,
          isHidden,
          onHidden,
        ),
      ],
    );
  }
}
