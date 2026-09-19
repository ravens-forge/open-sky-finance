import '../../app/routes.dart';
import '../../core/l10n.dart';

/// The main pages, in tab order; the index is the shell branch index.
enum MainPage {
  home(Routes.home),
  transactions(Routes.transactions),
  reminders(Routes.reminders),
  balanceSheet(Routes.balanceSheet),
  budgets(Routes.budgets),
  netIncome(Routes.netIncome),
  labels(Routes.labels);

  const MainPage(this.path);

  final String path;

  String label(AppLocalizations l10n) => switch (this) {
    MainPage.home => l10n.pageHome,
    MainPage.transactions => l10n.pageTransactions,
    MainPage.reminders => l10n.pageReminders,
    MainPage.balanceSheet => l10n.pageBalanceSheet,
    MainPage.budgets => l10n.pageBudgets,
    MainPage.netIncome => l10n.pageNetIncome,
    MainPage.labels => l10n.pageLabels,
  };
}
