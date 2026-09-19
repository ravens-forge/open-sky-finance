import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../widgets/add_fab.dart';
import '../widgets/app_drawer.dart';
import '../models/main_page.dart';

/// Top app bar, scrollable page tabs, drawer and FAB around the main pages.
/// Tapping a tab or swiping switches the shell branch, and vice versa.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;

  /// One navigator per branch, in [MainPage] order.
  final List<Widget> children;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: MainPage.values.length,
    initialIndex: widget.navigationShell.currentIndex,
    vsync: this,
  )..addListener(_onTabChanged);

  void _onTabChanged() {
    if (_tabs.index != widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(_tabs.index);
    }
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.navigationShell.currentIndex;
    if (index != _tabs.index) _tabs.animateTo(index);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.actionSearch,
            icon: const Icon(Icons.search),
            onPressed: () => _tabs.animateTo(MainPage.transactions.index),
          ),
          IconButton(
            tooltip: l10n.pageCalendar,
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => context.push(Routes.calendar),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            for (final page in MainPage.values) Tab(text: page.label(l10n)),
          ],
        ),
      ),
      drawer: AppDrawer(onHome: () => _tabs.animateTo(MainPage.home.index)),
      floatingActionButton: const AddFab(),
      body: TabBarView(
        controller: _tabs,
        children: [for (final child in widget.children) _KeepAlive(child)],
      ),
    );
  }
}

/// Keeps a branch alive while it is swiped out of view.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive(this.child);

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
