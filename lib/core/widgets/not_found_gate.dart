import 'package:flutter/material.dart';

import 'not_found_page.dart';

/// Looks an entity up once and shows [NotFoundPage] when it does not exist
/// (deleted, stale link), [child] otherwise. Key it by the ID.
class NotFoundGate extends StatefulWidget {
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
  State<NotFoundGate> createState() => _NotFoundGateState();
}

class _NotFoundGateState extends State<NotFoundGate> {
  late final Future<Object?> _found = widget.find();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _found,
      builder: (context, snapshot) => switch (snapshot) {
        AsyncSnapshot(connectionState: ConnectionState.done, data: null) =>
          NotFoundPage(onHome: widget.onHome),
        AsyncSnapshot(connectionState: ConnectionState.done) => widget.child,
        _ => const Scaffold(),
      },
    );
  }
}
