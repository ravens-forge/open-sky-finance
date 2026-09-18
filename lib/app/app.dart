import 'package:flutter/material.dart';
import 'package:open_sky_finance/l10n/generated/app_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder:
            (context) => Scaffold(
              body: Center(child: Text(AppLocalizations.of(context).appTitle)),
            ),
      ),
    );
  }
}
