import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/dates/year_month.dart';
import 'package:open_sky_finance/core/widgets/home_section_header.dart';
import 'package:open_sky_finance/data/enums/home_section_id.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/features/home/providers/home_providers.dart';
import 'package:open_sky_finance/features/home/widgets/cash_flow_chart.dart';
import 'package:open_sky_finance/features/home/widgets/net_income_chart.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

void main() {
  late ProviderContainer container;
  List<HomeSectionId> order() => [
    for (final s in container.read(homeSectionsProvider).requireValue) s.id,
  ];

  /// A USD wallet with a salary and "Rent" last month, "Bakery" today and
  /// [reminder] due in 2099 when set.
  Future<void> start(WidgetTester tester, {String? reminder}) async {
    container = await pumpApp(
      tester,
      showHome: true,
      seed: (db) async {
        await db.settingsRepository.set('main_currency', 'USD');
        final wallet = await addAssetsAccount(db, 'Wallet', currency: 'USD');
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1, 10);
        for (final (title, type, amount, date) in [
          ('Salary', TransactionType.income, m(3000), lastMonth),
          ('Rent', TransactionType.expense, -m(1200), lastMonth),
          ('Bakery', TransactionType.expense, -m(12.5), now),
        ]) {
          ok(
            await db.transactionsRepository.save(
              TransactionDraft(
                type: type,
                occurredAt: date,
                amount: amount,
                assetsAccountId: wallet,
                title: title,
              ),
            ),
          );
        }
        if (reminder != null) {
          await addReminder(
            db,
            'r1',
            assetsAccountId: wallet,
            title: reminder,
            nextDueAt: '2099-01-05T00:00:00',
          );
        }
      },
    );
  }

  testWidgets('a new user sees what each empty section needs', (tester) async {
    container = await pumpApp(tester, showHome: true);
    expect(find.text('FAVORITE ASSETS ACCOUNTS'), findsOneWidget);
    expect(
      find.text('Star the assets accounts you check most to see them here.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'No income or expenses yet. The chart appears after your first '
        'transaction.',
      ),
      findsNWidgets(2),
    );
    expect(find.text('Set a budget'), findsOneWidget);
    expect(
      find.text(
        'Not enough history yet. Come back next month to see the trend.',
      ),
      findsOneWidget,
    );
    expect(find.text('Upcoming reminders'), findsNothing);
  });

  testWidgets('charts show the chart accounts; a month drills down', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('\$1,787.50'), findsOneWidget); // net worth
    expect(find.text('−\$12.50'), findsOneWidget); // net income this month
    expect(find.byType(CashFlowChart), findsOneWidget);
    expect(find.byType(NetIncomeChart), findsOneWidget);
    expect(find.text('+\$1,787.50 in 6 months'), findsOneWidget);

    await tester.ensureVisible(find.text('Last 6 months').first);
    await tester.tap(find.text('Last 6 months').first);
    await settle(tester);
    expect(find.text('Last 12 months'), findsNWidgets(3));

    final now = YearMonth.of(DateTime.now());
    tester
        .widget<CashFlowChart>(find.byType(CashFlowChart))
        .onMonthTap(now.plus(-1));
    await settle(tester);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Bakery'), findsNothing);
  });

  testWidgets('sections move by drag, with a drop slot, and by action', (
    tester,
  ) async {
    await start(tester);
    final handle = find.descendant(
      of: find.widgetWithText(HomeSectionHeader, 'Cash flow'),
      matching: find.byIcon(Icons.drag_indicator),
    );
    await tester.ensureVisible(handle);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 260));
    await tester.pump();
    expect(find.text('Drop here'), findsOneWidget);
    await gesture.up();
    await settle(tester);
    expect(find.text('Drop here'), findsNothing);
    final moved = order();
    expect(
      moved.indexOf(HomeSectionId.cashFlow),
      greaterThan(moved.indexOf(HomeSectionId.budgetSummary)),
    );

    tester
        .widget<HomeSectionHeader>(
          find.widgetWithText(HomeSectionHeader, 'Net worth'),
        )
        .onMoveUp!();
    await settle(tester);
    final after = order();
    expect(
      after.indexOf(HomeSectionId.netWorth),
      moved.indexOf(HomeSectionId.netWorth) - 1,
    );
  });

  testWidgets('Arrange Home hides, shows and resets sections', (tester) async {
    await start(tester, reminder: 'Phone bill');
    unawaited(container.read(routerProvider).push(Routes.homeSections));
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find
            .ancestor(of: find.text('Cash flow'), matching: find.byType(Row))
            .first,
        matching: find.byType(Checkbox),
      ),
    );
    await settle(tester);
    await tester.ensureVisible(find.text('Upcoming reminders'));
    await tester.tap(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Upcoming reminders'),
              matching: find.byType(Row),
            )
            .first,
        matching: find.byType(Checkbox),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.byType(CashFlowChart), findsNothing);
    expect(find.text('Phone bill'), findsOneWidget);

    unawaited(container.read(routerProvider).push(Routes.homeSections));
    await settle(tester);
    await tester.ensureVisible(find.text('Reset to default order'));
    await tester.tap(find.text('Reset to default order'));
    await settle(tester);
    expect(order(), HomeSectionId.values);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.byType(CashFlowChart), findsOneWidget);
    expect(find.text('Phone bill'), findsNothing);
  });

  testWidgets('favorites are picked from the sheet', (tester) async {
    await start(tester);
    await tester.tap(find.text('Choose…'));
    await settle(tester);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Wallet'));
    await settle(tester);
    await tester.tap(find.text('Done · 1 selected'));
    await settle(tester);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });
}
