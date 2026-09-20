import '../../core/finance_colors.dart';
import '../../core/ids.dart';
import '../../core/l10n.dart';
import '../enums/assets_account_type.dart';
import '../enums/category_kind.dart';
import '../models/assets_account.dart';
import '../models/category.dart';
import '../models/category_group.dart';
import '../models/timestamps.dart';
import '../repositories/setting_keys.dart';
import 'app_database.dart';
import 'tables/assets_accounts_table.dart';
import 'tables/categories_table.dart';
import 'tables/category_groups_table.dart';

/// First-launch data: a cash assets account in [currency] (also the main
/// currency) and the default category groups, each with one category to start
/// from, named in [l10n]'s locale. After that they are plain user data, never
/// re-translated.
Future<void> seedDefaults(
  AppDatabase db,
  AppLocalizations l10n, {
  required String currency,
}) => db.transaction(() async {
  final now = DateTime.now().toUtc();
  final cash = AssetsAccount(
    id: newId(),
    name: l10n.seedAssetsAccountCash,
    type: AssetsAccountType.cash,
    currency: currency,
    isHidden: false,
    isFavorite: false,
    excludeFromNetWorth: false,
    creditLimit: null,
    sortOrder: 0,
    notes: '',
    timestamps: Timestamps.at(now),
  );
  await db
      .into(db.assetsAccountsTable)
      .insert(AssetsAccountTableRow.fromDomain(cash).toInsertable());

  // Income first, as everywhere else. Each group starts with one category so
  // the user can record something straight away.
  final groups = [
    (
      CategoryKind.income,
      l10n.seedCategoryGroupSalary,
      [(l10n.seedCategoryMonthlyPay, 'work')],
    ),
    (
      CategoryKind.income,
      l10n.seedCategoryGroupOtherIncome,
      [(l10n.seedCategoryOther, 'payments')],
    ),
    (
      CategoryKind.expense,
      l10n.seedCategoryGroupHousing,
      [(l10n.seedCategoryRent, 'home')],
    ),
    (
      CategoryKind.expense,
      l10n.seedCategoryGroupFood,
      [(l10n.seedCategoryGroceries, 'local_grocery_store')],
    ),
    (
      CategoryKind.expense,
      l10n.seedCategoryGroupTransport,
      [(l10n.seedCategoryFuel, 'local_gas_station')],
    ),
    (
      CategoryKind.expense,
      l10n.seedCategoryGroupUtilities,
      [(l10n.seedCategoryElectricity, 'bolt')],
    ),
    (
      CategoryKind.expense,
      l10n.seedCategoryGroupEntertainment,
      [(l10n.seedCategorySubscriptions, 'movie')],
    ),
    (
      CategoryKind.expense,
      l10n.seedCategoryGroupHealth,
      [(l10n.seedCategoryPharmacy, 'medication')],
    ),
    (
      CategoryKind.expense,
      l10n.seedCategoryGroupOther,
      [(l10n.seedCategoryOther, 'category')],
    ),
  ];

  final categories = <Category>[];
  final rows = <CategoryGroup>[];
  for (final (i, (kind, name, children)) in groups.indexed) {
    final group = CategoryGroup(
      id: newId(),
      name: name,
      kind: kind,
      isHidden: false,
      sortOrder: i,
    );
    rows.add(group);
    for (final (childName, icon) in children) {
      categories.add(
        Category(
          id: newId(),
          name: childName,
          groupId: group.id,
          icon: icon,
          color: categoryColors[categories.length % categoryColors.length],
          isHidden: false,
          sortOrder: categories.length,
        ),
      );
    }
  }

  await db.batch((b) {
    b.insertAll(db.categoryGroupsTable, [
      for (final g in rows) CategoryGroupTableRow.fromDomain(g).toInsertable(),
    ]);
    b.insertAll(db.categoriesTable, [
      for (final c in categories) CategoryTableRow.fromDomain(c).toInsertable(),
    ]);
  });

  await db.settingsRepository.set(SettingKeys.mainCurrency, currency);
});
