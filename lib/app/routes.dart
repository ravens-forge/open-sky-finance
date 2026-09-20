import '../data/enums/category_kind.dart';
import '../data/enums/transaction_type.dart';

/// Every route path of the app. Parameters carry only IDs and enum values.
abstract final class Routes {
  // Main pages (shell branches, in tab order).
  static const home = '/home';
  static const transactions = '/transactions';
  static const reminders = '/reminders';
  static const balanceSheet = '/balance-sheet';
  static const budgets = '/budgets';
  static const netIncome = '/net-income';
  static const labels = '/labels';

  // Other pages, pushed on the root navigator.
  static const calendar = '/calendar';
  static const assetsAccounts = '/assets-accounts';
  static const categories = '/categories';
  static const trash = '/trash';
  static const settings = '/settings';
  static const homeSections = '/settings/home-sections';
  static const backups = '/settings/backups';
  static const reportBug = '/settings/report-bug';
  static const onboarding = '/onboarding';
  static const erased = '/erased';
  static const support = '/support';

  static String newTransaction([
    TransactionType type = TransactionType.expense,
  ]) => '$transactions/new?type=${type.name}';
  static String transaction(String id) => '$transactions/$id';

  static const newReminder = '$reminders/new';
  static String reminder(String id) => '$reminders/$id';

  static const newAssetsAccount = '$assetsAccounts/new';
  static String assetsAccount(String id) => '$assetsAccounts/$id';
  static String editAssetsAccount(String id) => '$assetsAccounts/$id/edit';

  static String newCategory(CategoryKind kind, {String? groupId}) => Uri(
    path: '$categories/new',
    queryParameters: {'kind': kind.name, 'groupId': ?groupId},
  ).toString();
  static String category(String id) => '$categories/$id';
  static String newCategoryGroup(CategoryKind kind) =>
      '$categories/groups/new?kind=${kind.name}';
  static String categoryGroup(String id) => '$categories/groups/$id';
}
