import 'dart:async';

import 'package:flutter/material.dart';

import '../finance_colors.dart';
import '../l10n.dart';
import 'app_logo.dart';

/// Shown while the app opens its data. Stays blank paper for the first
/// [delay] so fast starts never flash it.
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({
    super.key,
    this.delay = const Duration(milliseconds: 400),
  });

  final Duration delay;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  late final Timer _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () => setState(() => _visible = true));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: !_visible
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
