import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_sky_finance/app/locale.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/theme.dart';
import 'package:open_sky_finance/app/theme_mode.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/widgets/launch_screen.dart';
import 'package:open_sky_finance/features/onboarding/providers/onboarding_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(userLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    // The router picks onboarding or Home once this has loaded.
    final onboarding = ref.watch(onboardingProvider);
    final loading = [
      locale,
      themeMode,
      onboarding,
    ].any((v) => !v.hasValue && !v.hasError);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale.value,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode.value,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => loading ? const LaunchScreen() : child!,
    );
  }
}
