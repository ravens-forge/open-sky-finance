import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/theme.dart';
import 'package:open_sky_finance/core/finance_colors.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/widgets/budget_bar.dart';
import 'package:open_sky_finance/core/widgets/day_header.dart';
import 'package:open_sky_finance/core/widgets/destructive_button.dart';
import 'package:open_sky_finance/core/widgets/error_page.dart';
import 'package:open_sky_finance/core/widgets/field_error.dart';
import 'package:open_sky_finance/core/widgets/form_error_summary.dart';
import 'package:open_sky_finance/core/widgets/info_tooltip.dart';
import 'package:open_sky_finance/core/widgets/launch_screen.dart';
import 'package:open_sky_finance/core/widgets/leader_row.dart';
import 'package:open_sky_finance/core/widgets/ledger_dialog.dart';
import 'package:open_sky_finance/core/widgets/reminder_row.dart';
import 'package:open_sky_finance/core/widgets/transaction_row.dart';
import 'package:open_sky_finance/core/widgets/warning_banner.dart';

Widget _app(
  Widget child, {
  Locale locale = const Locale('en'),
  ThemeData? theme,
  double textScale = 1,
}) => MaterialApp(
  locale: locale,
  theme: theme ?? lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery.withClampedTextScaling(
    minScaleFactor: textScale,
    maxScaleFactor: textScale,
    child: Scaffold(body: child),
  ),
);

void main() {
  group('theme', () {
    test('explicit tokens in both themes', () {
      expect(lightTheme.colorScheme.primary, const Color(0xFF0F5C4D));
      expect(lightTheme.colorScheme.surface, const Color(0xFFFAF7F0));
      expect(darkTheme.colorScheme.primary, const Color(0xFF5FC2A8));
      expect(darkTheme.colorScheme.surface, const Color(0xFF16130F));
      for (final theme in [lightTheme, darkTheme]) {
        final c = theme.colorScheme;
        final f = theme.extension<FinanceColors>()!;
        expect(f.expense, c.error);
        expect(f.transfer, c.tertiary);
        expect(f.sunken, c.surfaceContainerHighest);
        expect(f.chartSeries.take(2), [c.primary, c.secondary]);
      }
      expect(
        lightTheme.extension<FinanceColors>()!.income,
        const Color(0xFF1F7A3E),
      );
    });

    test('serif and sans roles use tabular figures', () {
      final text = lightTheme.textTheme;
      expect(text.hero.fontFamily, serif);
      expect(text.sectionTitle.fontFamily, serif);
      expect(text.rowTitle.fontFamily, sans);
      expect(text.eyebrow.letterSpacing, closeTo(1.44, 0.001));
      expect(
        text.rowAmount.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('pill buttons, square sheets and dialogs with an ink rule', () {
      final shape = lightTheme.filledButtonTheme.style!.shape!.resolve({});
      expect(shape, isA<StadiumBorder>());
      final dialog = lightTheme.dialogTheme.shape! as Border;
      expect(dialog.top.width, 2);
      expect(dialog.top.color, lightTheme.colorScheme.onSurface);
      expect(lightTheme.bottomSheetTheme.shape, isA<Border>());
    });
  });

  test('budget bar state thresholds', () {
    expect(budgetState(79, 100), BudgetState.under);
    expect(budgetState(80, 100), BudgetState.near);
    expect(budgetState(100, 100), BudgetState.usedUp);
    expect(budgetState(101, 100), BudgetState.over);
    expect(budgetState(0, 0), BudgetState.under);
    expect(budgetState(1, 0), BudgetState.over);
  });

  testWidgets('info tooltip: one open at a time, closes on tap outside', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoTooltip(label: 'About A', text: 'First'),
            InfoTooltip(label: 'About B', text: 'Second'),
          ],
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('About A'));
    await tester.pump();
    expect(find.text('First'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('About B'));
    await tester.pump();
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    await tester.tapAt(const Offset(200, 500));
    await tester.pump();
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('launch screen waits 400 ms', (tester) async {
    await tester.pumpWidget(_app(const LaunchScreen()));
    expect(find.text('Open Sky Finance'), findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Open Sky Finance'), findsOneWidget);
    expect(
      find.text('Offline · your data stays on this device'),
      findsOneWidget,
    );
  });

  testWidgets('rows survive French at 200 %', (tester) async {
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const DayHeader(
                title: 'Jeudi 17 septembre',
                trailing: Text('−47,40 €'),
              ),
              const TransactionRow(
                icon: Icons.home_outlined,
                iconColor: Colors.teal,
                title: 'Loyer de l’appartement du centre-ville',
                subtitle: '25 sept. · Logement · Compte courant',
                amount: Text('−850,00 €'),
                labels: ['Maison'],
                scheduled: true,
              ),
              const LeaderRow(
                name: 'Compte d’épargne à long terme de la famille',
                amount: Text('12 345,67 €'),
              ),
              ReminderRow(
                icon: Icons.bolt,
                iconColor: Colors.purple,
                title: 'Facture d’électricité',
                schedule: 'Mensuel · Services publics',
                due: 'Était dû le 15 sept.',
                overdue: true,
                amount: const Text('−62,30 €'),
                onRecord: () {},
                onSkip: () {},
              ),
              const ReminderRow(
                icon: Icons.work,
                iconColor: Colors.green,
                title: 'Salaire',
                schedule: 'Mensuel',
                due: 'Dans 8 jours',
                amount: Text('+3 200,00 €'),
              ),
              const WarningBanner(
                lead: 'Attention.',
                text: 'Sauvegarde en pause.',
              ),
              const FormErrorSummary(count: 2),
              const FieldError('Saisissez un montant supérieur à 0'),
              const BudgetBar(spentMicros: 138, budgetMicros: 120),
            ],
          ),
        ),
        locale: const Locale('fr'),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Planifié'), findsOneWidget);
    expect(find.text('Automatique'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
    expect(find.textContaining('2 champs à vérifier.'), findsOneWidget);
  });

  testWidgets('dialogs and error page in the dark theme', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showLedgerDialog<void>(
              context: context,
              kind: DialogKind.error,
              title: 'Delete permanently?',
              body: 'This can’t be undone.',
              actions: [
                TextButton(onPressed: () {}, child: const Text('Cancel')),
                DestructiveButton(
                  onPressed: () {},
                  child: const Text('Delete'),
                ),
              ],
            ),
            child: const Text('open'),
          ),
        ),
        theme: darkTheme,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete permanently?'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await tester.pumpWidget(
      _app(
        ErrorPage(
          title: 'Couldn’t load transactions',
          message: 'Nothing was changed.',
          onRetry: () {},
          onReport: () {},
          note: 'Error code DB-READ',
        ),
      ),
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Report a bug'), findsOneWidget);
  });
}
