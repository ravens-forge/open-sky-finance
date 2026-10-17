import 'package:flutter/material.dart';

/// Keeps [child] above the on-screen keyboard. A [Scaffold] shrinks its body
/// for the keyboard but leaves its `bottomNavigationBar` underneath it, and a
/// modal bottom sheet does not move at all.
class AboveKeyboard extends StatelessWidget {
  const AboveKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: child,
  );
}
