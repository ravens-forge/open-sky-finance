import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'not_found_page.dart';

/// Looks an entity up once and shows [NotFoundPage] when it does not exist
/// (deleted, stale link), [child] otherwise. Key it by the ID.
class NotFoundGate extends HookWidget {
  const NotFoundGate({
    super.key,
    required this.find,
    required this.onHome,
    required this.child,
  });

  final Future<Object?> Function() find;
  final VoidCallback onHome;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final snapshot = useFuture(useMemoized(find));
    return switch (snapshot) {
      AsyncSnapshot(connectionState: ConnectionState.done, data: null) =>
        NotFoundPage(onHome: onHome),
      AsyncSnapshot(connectionState: ConnectionState.done) => child,
      _ => const Scaffold(),
    };
  }
}
