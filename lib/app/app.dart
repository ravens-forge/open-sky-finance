import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_sky_finance/app/locale.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/theme.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/widgets/launch_screen.dart';
import 'package:open_sky_finance/features/onboarding/onboarding_pending.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(onboardingPendingProvider).isLoading;

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(userLocaleProvider),
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => loading ? const LaunchScreen() : child!,
    );
  }
}
