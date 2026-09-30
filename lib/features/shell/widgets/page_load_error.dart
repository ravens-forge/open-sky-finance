import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/error_page.dart';

class PageLoadError extends ConsumerWidget {
  const PageLoadError({super.key, required this.providers});

  final List<ProviderOrFamily> providers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ErrorPage(
      title: l10n.errorLoadTitle,
      message: l10n.errorLoadFailed,
      note: l10n.errorLoadNote('DB-READ'),
      onRetry: () => providers.forEach(ref.invalidate),
      onReport: () => context.push(Routes.reportBug),
    );
  }
}
