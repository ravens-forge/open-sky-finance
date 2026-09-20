import 'package:flutter/material.dart';

import '../l10n.dart';
import 'category_icons.dart';

/// Category colours (ARGB, as stored), in picker order.
const categoryColors = <int>[
  0xFF0F5C4D, // pine
  0xFF9A5B00, // ochre
  0xFFB8391F, // red
  0xFF7D5BA6, // purple
  0xFF2F7F72, // teal
  0xFF2B5FAE, // blue
  0xFF6A5F51, // stone
];

/// Grid of [categoryIcons], six per row. The selected one is tinted and ringed in
/// [color] (the category's colour).
class CategoryIconPicker extends StatelessWidget {
  const CategoryIconPicker({
    super.key,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 6,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final MapEntry(:key, :value) in categoryIcons.entries)
          IconButton(
            isSelected: key == selected,
            tooltip: _iconLabel(l10n, key),
            onPressed: () => onSelected(key),
            icon: Icon(value),
            style: key == selected
                ? IconButton.styleFrom(
                    fixedSize: const Size.square(48),
                    foregroundColor: color,
                    backgroundColor: color.withValues(alpha: 0.14),
                    side: BorderSide(color: color, width: 2),
                  )
                : IconButton.styleFrom(
                    fixedSize: const Size.square(48),
                    foregroundColor: scheme.onSurfaceVariant,
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
          ),
      ],
    );
  }
}

/// Colour swatches for a category; every category has one of its own.
class CategoryColorPicker extends StatelessWidget {
  const CategoryColorPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ink = Theme.of(context).colorScheme.onSurface;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, value) in categoryColors.indexed)
          IconButton(
            isSelected: value == selected,
            tooltip: _colorLabel(l10n, i),
            onPressed: () => onSelected(value),
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(value),
                shape: BoxShape.circle,
                border: value == selected
                    ? Border.all(color: ink, width: 2)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

String _colorLabel(AppLocalizations l10n, int index) => [
  l10n.categoryColorPine,
  l10n.categoryColorOchre,
  l10n.categoryColorRed,
  l10n.categoryColorPurple,
  l10n.categoryColorTeal,
  l10n.categoryColorBlue,
  l10n.categoryColorStone,
][index];

String _iconLabel(AppLocalizations l10n, String key) => switch (key) {
  'home' => l10n.categoryIconHome,
  'local_grocery_store' => l10n.categoryIconGroceries,
  'restaurant' => l10n.categoryIconRestaurant,
  'local_cafe' => l10n.categoryIconCafe,
  'shopping_bag' => l10n.categoryIconShopping,
  'checkroom' => l10n.categoryIconClothing,
  'directions_car' => l10n.categoryIconCar,
  'local_gas_station' => l10n.categoryIconFuel,
  'directions_bus' => l10n.categoryIconPublicTransport,
  'flight' => l10n.categoryIconFlights,
  'bolt' => l10n.categoryIconElectricity,
  'water_drop' => l10n.categoryIconWater,
  'wifi' => l10n.categoryIconInternet,
  'smartphone' => l10n.categoryIconPhone,
  'receipt_long' => l10n.categoryIconBills,
  'build' => l10n.categoryIconRepairs,
  'local_activity' => l10n.categoryIconEntertainment,
  'movie' => l10n.categoryIconCinema,
  'sports_esports' => l10n.categoryIconGames,
  'fitness_center' => l10n.categoryIconFitness,
  'local_hospital' => l10n.categoryIconHealth,
  'medication' => l10n.categoryIconPharmacy,
  'pets' => l10n.categoryIconPets,
  'child_care' => l10n.categoryIconChildren,
  'school' => l10n.categoryIconEducation,
  'menu_book' => l10n.categoryIconBooks,
  'card_giftcard' => l10n.categoryIconGifts,
  'favorite' => l10n.categoryIconDonations,
  'work' => l10n.categoryIconSalary,
  'payments' => l10n.categoryIconCash,
  'savings' => l10n.categoryIconSavings,
  'trending_up' => l10n.categoryIconInvestments,
  'account_balance' => l10n.categoryIconBank,
  _ => l10n.categoryIconOther,
};
