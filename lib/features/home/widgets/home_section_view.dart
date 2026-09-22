import 'package:flutter/material.dart';

import '../../../data/enums/home_section_id.dart';
import '../models/home_section_place.dart';
import 'budget_summary_section.dart';
import 'cash_flow_section.dart';
import 'favorite_accounts_section.dart';
import 'net_income_section.dart';
import 'net_worth_section.dart';
import 'summary_section.dart';
import 'upcoming_reminders_section.dart';

class HomeSectionView extends StatelessWidget {
  const HomeSectionView({super.key, required this.id, required this.place});

  final HomeSectionId id;
  final HomeSectionPlace place;

  @override
  Widget build(BuildContext context) => switch (id) {
    HomeSectionId.favoriteAccounts => FavoriteAccountsSection(place: place),
    HomeSectionId.summary => const SummarySection(),
    HomeSectionId.cashFlow => CashFlowSection(place: place),
    HomeSectionId.budgetSummary => BudgetSummarySection(place: place),
    HomeSectionId.netIncome => NetIncomeSection(place: place),
    HomeSectionId.netWorth => NetWorthSection(place: place),
    HomeSectionId.upcomingReminders => UpcomingRemindersSection(place: place),
  };
}
