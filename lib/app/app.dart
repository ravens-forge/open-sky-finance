import 'package:flutter/material.dart';
import 'package:open_sky_finance/core/finance_colors.dart';
import 'package:open_sky_finance/core/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: const [FinanceColors.light]),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        extensions: const [FinanceColors.dark],
      ),
      home: Builder(
        builder: (context) =>
            Scaffold(body: Center(child: Text(context.l10n.appTitle))),
      ),
    );
  }
}
