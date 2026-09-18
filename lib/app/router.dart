import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_sky_finance/core/l10n.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          Scaffold(body: Center(child: Text(context.l10n.appTitle))),
    ),
  ],
);
