import 'package:flutter/material.dart';

/// Icon for unknown keys.
const fallbackCategoryIcon = Icons.category_outlined;

/// Category icons by stored key: the Material icon name in snake_case.
///
/// A static map because Flutter cannot look icons up by name at runtime, and it keeps
/// icon tree-shaking working. The order is the order of the icon picker.
const categoryIcons = <String, IconData>{
  'home': Icons.home_outlined,
  'local_grocery_store': Icons.local_grocery_store_outlined,
  'restaurant': Icons.restaurant_outlined,
  'local_cafe': Icons.local_cafe_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'checkroom': Icons.checkroom_outlined,
  'directions_car': Icons.directions_car_outlined,
  'local_gas_station': Icons.local_gas_station_outlined,
  'directions_bus': Icons.directions_bus_outlined,
  'flight': Icons.flight_outlined,
  'bolt': Icons.bolt_outlined,
  'water_drop': Icons.water_drop_outlined,
  'wifi': Icons.wifi_outlined,
  'smartphone': Icons.smartphone_outlined,
  'receipt_long': Icons.receipt_long_outlined,
  'build': Icons.build_outlined,
  'local_activity': Icons.local_activity_outlined,
  'movie': Icons.movie_outlined,
  'sports_esports': Icons.sports_esports_outlined,
  'fitness_center': Icons.fitness_center_outlined,
  'local_hospital': Icons.local_hospital_outlined,
  'medication': Icons.medication_outlined,
  'pets': Icons.pets_outlined,
  'child_care': Icons.child_care_outlined,
  'school': Icons.school_outlined,
  'menu_book': Icons.menu_book_outlined,
  'card_giftcard': Icons.card_giftcard_outlined,
  'favorite': Icons.favorite_outline,
  'work': Icons.work_outline,
  'payments': Icons.payments_outlined,
  'savings': Icons.savings_outlined,
  'trending_up': Icons.trending_up_outlined,
  'account_balance': Icons.account_balance_outlined,
  'category': fallbackCategoryIcon,
};

IconData categoryIcon(String key) => categoryIcons[key] ?? fallbackCategoryIcon;
