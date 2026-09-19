import 'package:flutter/material.dart';

/// A route whose screen is not built yet: its top bar and an empty body.
class StubPage extends StatelessWidget {
  const StubPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)));
  }
}
