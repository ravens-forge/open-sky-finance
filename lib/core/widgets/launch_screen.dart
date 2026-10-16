import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../finance_colors.dart';
import '../l10n.dart';
import 'app_logo.dart';

/// Shown while the app opens its data. Stays blank paper for the first
/// [delay] so fast starts never flash it.
class LaunchScreen extends HookWidget {
  const LaunchScreen({
    super.key,
    this.delay = const Duration(milliseconds: 400),
  });

  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final visible = useState(false);
    useEffect(() {
      final timer = Timer(delay, () => visible.value = true);
      return timer.cancel;
    }, const []);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: !visible.value
          ? const SizedBox.expand()
          : Semantics(
              container: true,
              liveRegion: true,
              label: l10n.launchSemantic,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 18,
                      children: [
                        const AppLogo(height: AppLogo.launchHeight),
                        Text(
                          l10n.appTitle,
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(
                          width: 140,
                          child: ExcludeSemantics(
                            child: LinearProgressIndicator(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: FinanceColors.of(context).muted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.appPrivacyLine,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
