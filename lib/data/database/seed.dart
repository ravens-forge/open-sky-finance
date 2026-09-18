import '../../core/ids.dart';
import '../../core/l10n.dart';
import '../../core/widgets/category_pickers.dart';
import '../enums/assets_account_type.dart';
import '../enums/category_kind.dart';
import '../models/assets_account.dart';
import '../models/category.dart';
import '../models/timestamps.dart';
import 'app_database.dart';
import 'tables/setting_keys.dart';
import 'tables/assets_accounts_table.dart';
import 'tables/categories_table.dart';

/// First-launch data: a cash assets account in [currency] (also the main
/// currency) and the default category groups, named in [l10n]'s locale. After
/// that they are plain user data, never re-translated.
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

  final groups = [
    (CategoryKind.expense, l10n.seedCategoryGroupHousing, 'home'),
    (CategoryKind.expense, l10n.seedCategoryGroupFood, 'local_grocery_store'),
    (CategoryKind.expense, l10n.seedCategoryGroupTransport, 'directions_bus'),
    (CategoryKind.expense, l10n.seedCategoryGroupUtilities, 'bolt'),
    (CategoryKind.expense, l10n.seedCategoryGroupEntertainment, 'movie'),
    (CategoryKind.expense, l10n.seedCategoryGroupHealth, 'local_hospital'),
    (CategoryKind.expense, l10n.seedCategoryGroupOther, 'category'),
    (CategoryKind.income, l10n.seedCategoryGroupSalary, 'work'),
    (CategoryKind.income, l10n.seedCategoryGroupOtherIncome, 'payments'),
  ];
  await db.batch(
    (b) => b.insertAll(db.categoriesTable, [
      for (final (i, (kind, name, icon)) in groups.indexed)
        CategoryTableRow.fromDomain(
          Category(
            id: newId(),
            name: name,
            kind: kind,
            parentId: null,
            icon: icon,
            color: categoryColors[i % categoryColors.length],
            isHidden: false,
            sortOrder: i,
          ),
        ).toInsertable(),
    ]),
  );

  await db.settingsRepository.set(SettingKeys.mainCurrency, currency);
});
