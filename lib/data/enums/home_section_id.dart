enum HomeSectionId {
  favoriteAccounts,
  summary,
  cashFlow,
  budgetSummary,
  netIncome,
  netWorth,
  upcomingReminders;

  bool get visibleByDefault => this != upcomingReminders;
}
