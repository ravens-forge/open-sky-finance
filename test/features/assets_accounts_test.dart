import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/money/currency_converter.dart';
import 'package:open_sky_finance/core/reorder_ids.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/data/enums/assets_account_type.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/assets_account.dart';
import 'package:open_sky_finance/data/models/assets_account_draft.dart';
import 'package:open_sky_finance/data/models/money.dart';
import 'package:open_sky_finance/data/models/timestamps.dart';
import 'package:open_sky_finance/data/models/transaction.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/models/transfer_destination.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/features/assets_accounts/models/assets_account_month.dart';
import 'package:open_sky_finance/features/assets_accounts/models/assets_account_with_balance.dart';
import 'package:open_sky_finance/features/assets_accounts/models/assets_accounts_side.dart';
import 'package:open_sky_finance/features/assets_accounts/models/credit_usage.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

final _stamp = Timestamps(
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

AssetsAccountWithBalance _account(
  String id,
  AssetsAccountType type,
  int balance, {
  String currency = 'EUR',
  bool hidden = false,
  bool excluded = false,
  int? creditLimit,
}) => AssetsAccountWithBalance(
  AssetsAccount(
    id: id,
    name: id,
    type: type,
    currency: currency,
    isHidden: hidden,
    isFavorite: false,
    excludeFromNetWorth: excluded,
    creditLimit: creditLimit,
    sortOrder: 0,
    notes: '',
    timestamps: _stamp,
  ),
  balance,
);

Transaction _tx(
  String id,
  DateTime at,
  int amount, {
  TransactionType type = TransactionType.expense,
  String from = 'a',
  String? to,
  int? received,
}) => Transaction(
  id: id,
  type: type,
  occurredAt: at,
  title: '',
  amount: Money(amount, 'EUR'),
  assetsAccountId: from,
  transfer: to == null
      ? null
      : TransferDestination(assetsAccountId: to, amountReceived: received),
  categoryId: null,
  notes: '',
  reminderId: null,
  deletedAt: null,
  timestamps: _stamp,
);

Future<String> _add(
  WidgetTester tester,
  AppDatabase db,
  String name, {
  AssetsAccountType type = AssetsAccountType.bank,
  int openingBalance = 0,
  bool hidden = false,
  int? creditLimit,
}) async => ok(
  (await tester.runAsync(
    () => db.assetsAccountsRepository.save(
      AssetsAccountDraft(
        name: name,
        type: type,
        currency: 'EUR',
        openingBalance: openingBalance,
        openingBalanceDate: DateTime.now(),
        isHidden: hidden,
        creditLimit: creditLimit,
      ),
    ),
  ))!,
);

void main() {
  test('reorder moves within a group and keeps the other ids in place', () {
    expect(reorderIds(['a', 'x', 'b', 'c'], ['a', 'b', 'c'], 2, 0), [
      'c',
      'x',
      'a',
      'b',
    ]);
    expect(reorderIds(['a', 'b', 'y'], ['a', 'b'], 0, 1), ['b', 'a', 'y']);
  });

  test('groups by side and type; subtotals skip hidden and excluded', () {
    final sides = groupAssetsAccounts([
      _account('loan', AssetsAccountType.loan, -m(500)),
      _account('bank', AssetsAccountType.bank, m(100)),
      _account('cash', AssetsAccountType.cash, m(20)),
      _account('bank2', AssetsAccountType.bank, m(1), hidden: true),
      _account('house', AssetsAccountType.property, m(9), excluded: true),
      _account('usd', AssetsAccountType.bank, m(10), currency: 'USD'),
      _account('gbp', AssetsAccountType.bank, m(3), currency: 'GBP'),
    ], CurrencyConverter('EUR', {'USD': Decimal.parse('0.9')}));
    expect([for (final s in sides) s.isLiability], [false, true]);
    expect(
      [for (final g in sides[0].groups) g.type],
      [
        AssetsAccountType.bank,
        AssetsAccountType.cash,
        AssetsAccountType.property,
      ],
    );
    expect(
      [for (final a in sides[0].groups[0].accounts) a.account.id],
      ['bank', 'bank2', 'usd', 'gbp'],
    );
    expect(sides[0].total.amount, m(129));
    expect(sides[0].total.approximate, isTrue);
    expect(sides[0].total.notIncluded, {'GBP': m(3)});
    expect(sides[1].total.amount, -m(500));
  });

  test('credit usage only for credit cards with a limit', () {
    final card = _account(
      'visa',
      AssetsAccountType.creditCard,
      -m(30),
      creditLimit: m(300),
    );
    final usage = CreditUsage.of(card.account, card.balance)!;
    expect(usage.used, m(30));
    expect(usage.available, m(270));
    expect(usage.fraction, closeTo(0.1, 1e-9));
    expect(CreditUsage.of(card.account, m(5))!.used, 0);
    final bank = _account('bank', AssetsAccountType.bank, -m(30));
    expect(CreditUsage.of(bank.account, bank.balance), isNull);
  });

  test('month: money in and out, days with their end balance', () {
    final month = AssetsAccountMonth.of('a', [
      _tx('3', DateTime(2026, 9, 15, 20), -m(24)),
      _tx('2', DateTime(2026, 9, 15, 9), -m(86)),
      _tx(
        '1',
        DateTime(2026, 9, 1),
        m(520),
        type: TransactionType.transfer,
        from: 'b',
        to: 'a',
      ),
      _tx(
        '0',
        DateTime(2026, 9, 1),
        m(10),
        type: TransactionType.transfer,
        to: 'b',
      ),
    ], -m(680));
    expect(month.moneyIn, m(520));
    expect(month.moneyOut, -m(120));
    expect(
      [for (final d in month.days) d.date],
      [DateTime(2026, 9, 15), DateTime(2026, 9, 1)],
    );
    expect([for (final d in month.days) d.balance], [-m(680), -m(570)]);
    expect(month.days[1].transactions.length, 2);
  });

  group('screens', () {
    late ProviderContainer container;
    late AppDatabase db;

    // The page's list, not the text fields inside it.
    final page = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> open(WidgetTester tester, String path) async {
      container.read(routerProvider).go(path);
      await settle(tester);
    }

    Future<void> start(WidgetTester tester) async {
      container = await pumpApp(tester);
      db = container.read(appDatabaseProvider);
      await tester.runAsync(
        () => db.settingsRepository.set(SettingKeys.mainCurrency, 'EUR'),
      );
    }

    testWidgets('list: groups, subtotals, favorite, hidden', (tester) async {
      await start(tester);
      final checking = await _add(
        tester,
        db,
        'Checking',
        openingBalance: m(100),
      );
      await _add(
        tester,
        db,
        'Visa',
        type: AssetsAccountType.creditCard,
        openingBalance: -m(30),
        creditLimit: m(300),
      );
      await _add(tester, db, 'Old', type: AssetsAccountType.cash, hidden: true);
      await open(tester, Routes.assetsAccounts);

      expect(find.text('Assets'), findsOneWidget);
      expect(find.text('Liabilities'), findsOneWidget);
      expect(find.text('BANK'), findsOneWidget);
      expect(find.text('CREDIT CARD'), findsOneWidget);
      expect(find.text('€100.00'), findsNWidgets(2));
      expect(find.text('€270.00 available of €300.00'), findsOneWidget);
      expect(find.text('Old'), findsNothing);

      await tester.tap(find.text('Show hidden assets accounts (1)'));
      await settle(tester);
      expect(find.text('Old'), findsOneWidget);

      await tester.tap(find.byTooltip('Favorite assets account: Checking'));
      await settle(tester);
      final saved = await tester.runAsync(
        () => db.assetsAccountsRepository.findById(checking),
      );
      expect(saved!.isFavorite, isTrue);
    });

    testWidgets('editor creates an assets account with its opening balance', (
      tester,
    ) async {
      await start(tester);
      await open(tester, Routes.newAssetsAccount);

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Savings');
      await tester.enterText(
        find.widgetWithText(TextField, 'Opening balance'),
        '1,250.50',
      );
      await tester.tap(find.text('Save'));
      await settle(tester);

      final all = await tester.runAsync(
        () => db.assetsAccountsRepository.watchAll().first,
      );
      expect(all!.single.name, 'Savings');
      expect(all.single.currency, 'EUR');
      final opening = await tester.runAsync(
        () => db.assetsAccountsRepository.openingBalanceOf(all.single.id),
      );
      expect(opening!.amount.micros, m(1250.5));
    });

    testWidgets('detail: balance and the month transactions', (tester) async {
      await start(tester);
      final id = await _add(tester, db, 'Wallet', openingBalance: m(40));
      await open(tester, Routes.assetsAccount(id));

      expect(find.text('CURRENT BALANCE'), findsOneWidget);
      expect(find.text('€40.00'), findsWidgets);
      expect(find.text('Balance over time'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Opening balance'),
        200,
        scrollable: page,
      );
      expect(find.text('Balance €40.00'), findsOneWidget);
    });

    testWidgets('delete counts transactions and offers to hide', (
      tester,
    ) async {
      await start(tester);
      final other = await _add(tester, db, 'Other');
      final id = await _add(tester, db, 'Visa', openingBalance: m(5));
      await tester.runAsync(
        () => db.transactionsRepository.save(
          TransactionDraft(
            type: TransactionType.expense,
            occurredAt: DateTime(2026, 3, 1),
            amount: -m(3),
            assetsAccountId: id,
          ),
        ),
      );
      await open(tester, Routes.editAssetsAccount(id));

      Future<void> tapDelete() async {
        await tester.scrollUntilVisible(
          find.text('Delete assets account'),
          200,
          scrollable: page,
        );
        await tester.tap(find.text('Delete assets account'));
        await settle(tester);
      }

      await tapDelete();
      expect(
        find.text(
          '1 transaction will be deleted permanently. '
          "This can't be undone.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Hide “Visa”'));
      await settle(tester);
      var saved = await tester.runAsync(
        () => db.assetsAccountsRepository.findById(id),
      );
      expect(saved!.isHidden, isTrue);

      await open(tester, Routes.editAssetsAccount(id));
      await tapDelete();
      await tester.tap(find.text('Delete'));
      await settle(tester);
      saved = await tester.runAsync(
        () => db.assetsAccountsRepository.findById(id),
      );
      expect(saved, isNull);
      expect(
        container.read(routerProvider).state.uri.toString(),
        Routes.assetsAccounts,
      );
      expect(find.text('Other'), findsOneWidget);
      expect(other, isNotEmpty);
    });
  });
}
