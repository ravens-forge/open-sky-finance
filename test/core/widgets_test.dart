import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/theme.dart';
import 'package:open_sky_finance/core/finance_colors.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/money/format_money.dart';
import 'package:open_sky_finance/core/widgets/amount_text.dart';
import 'package:open_sky_finance/core/widgets/category_icons.dart';
import 'package:open_sky_finance/core/widgets/category_pickers.dart';
import 'package:open_sky_finance/core/widgets/empty_state.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  theme: lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

final _colors = lightTheme.extension<FinanceColors>()!;

void main() {
  test('unknown category icons fall back', () {
    expect(categoryIcon('local_gas_station'), Icons.local_gas_station_outlined);
    expect(categoryIcon('no_such_icon'), fallbackCategoryIcon);
  });

  group('AmountText', () {
    Text textOf(WidgetTester tester) => tester.widget<Text>(find.byType(Text));

    for (final (locale, expense) in [
      ('en', 'expense'),
      ('es', 'gasto'),
      ('fr', 'dépense'),
    ]) {
      testWidgets('expense in $locale', (tester) async {
        await tester.pumpWidget(
          _app(
            const AmountText(-12500000, currency: 'EUR'),
            locale: Locale(locale),
          ),
        );
        final amount = formatMoney(12500000, currency: 'EUR', locale: locale);
        final text = textOf(tester);
        expect(text.data, '−$amount');
        expect(text.semanticsLabel, '$expense, $amount');
        expect(text.style!.color, _colors.expense);
      });
    }

    testWidgets('income, transfer, balance, zero', (tester) async {
      Future<Text> pump(AmountText widget) async {
        await tester.pumpWidget(_app(widget));
        return textOf(tester);
      }

      var text = await pump(const AmountText(2000000, currency: 'EUR'));
      expect(text.data, '+€2.00');
      expect(text.semanticsLabel, 'income, €2.00');
      expect(text.style!.color, _colors.income);

      text = await pump(
        const AmountText(
          2000000,
          currency: 'EUR',
          amountStyle: AmountStyle.transfer,
        ),
      );
      expect(text.data, '⇄ €2.00');
      expect(text.style!.color, _colors.transfer);

      text = await pump(
        const AmountText(
          2000000,
          currency: 'EUR',
          amountStyle: AmountStyle.balance,
        ),
      );
      expect(text.data, '€2.00');
      expect(text.semanticsLabel, isNull);

      text = await pump(
        const AmountText(
          -2000000,
          currency: 'EUR',
          amountStyle: AmountStyle.balance,
        ),
      );
      expect(text.data, '−€2.00');
      expect(text.semanticsLabel, 'minus €2.00');

      text = await pump(const AmountText(0, currency: 'EUR'));
      expect(text.data, '€0.00');
    });
  });

  testWidgets('EmptyState shows title, message and actions', (tester) async {
    await tester.pumpWidget(
      _app(
        EmptyState(
          title: 'Nothing yet',
          message: 'Add one',
          actions: [FilledButton(onPressed: () {}, child: const Text('Add'))],
        ),
      ),
    );
    expect(find.text('Nothing yet'), findsOneWidget);
    expect(find.text('Add one'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('icon picker labels every icon and reports selection', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      _app(
        CategoryIconPicker(
          selected: 'home',
          color: Colors.teal,
          onSelected: (key) => picked = key,
        ),
        locale: const Locale('fr'),
      ),
    );
    expect(find.byType(IconButton), findsNWidgets(categoryIcons.length));
    expect(find.byTooltip('Logement'), findsOneWidget);
    await tester.tap(find.byTooltip('Carburant'));
    expect(picked, 'local_gas_station');
  });

  testWidgets('colour picker offers "Group" as null', (tester) async {
    int? picked = 1;
    await tester.pumpWidget(
      _app(
        CategoryColorPicker(
          selected: categoryColors.first,
          groupColor: categoryColors.last,
          onSelected: (value) => picked = value,
        ),
        locale: const Locale('es'),
      ),
    );
    await tester.tap(find.text('Grupo'));
    expect(picked, isNull);
    await tester.tap(find.byTooltip('Azul'));
    expect(picked, 0xFF2B5FAE);
  });
}
