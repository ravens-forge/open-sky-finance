import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../widgets/add_fab.dart';
import '../widgets/app_drawer.dart';
import '../models/main_page.dart';

/// Top app bar, scrollable page tabs, drawer and FAB around the main pages.
/// Tapping a tab or swiping switches the shell branch, and vice versa. Back
/// on any tab but Home goes to Home instead of leaving the app.
class MainShell extends HookWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;

  /// One navigator per branch, in [MainPage] order.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final index = navigationShell.currentIndex;
    final tabs = useTabController(
      initialLength: MainPage.values.length,
      initialIndex: index,
    );
    // Tab or swipe → branch, on the shell of the latest build.
    final shell = useRef(navigationShell)..value = navigationShell;
    useEffect(() {
      void select() {
        if (tabs.index != shell.value.currentIndex) {
          shell.value.goBranch(tabs.index);
        }
      }

      tabs.addListener(select);
      return () => tabs.removeListener(select);
    }, [tabs]);
    // Branch (a link, a notification) → tab.
    useEffect(() {
      if (tabs.index != index) tabs.animateTo(index);
      return null;
    }, [index]);
    void showHome() => tabs.animateTo(MainPage.home.index);

    return PopScope(
      canPop: index == MainPage.home.index,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) showHome();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: [
            IconButton(
              tooltip: l10n.actionSearch,
              icon: const Icon(Icons.search),
              onPressed: () => tabs.animateTo(MainPage.transactions.index),
            ),
            IconButton(
              tooltip: l10n.pageCalendar,
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: () => context.push(Routes.calendar),
            ),
          ],
          bottom: TabBar(
            controller: tabs,
            isScrollable: true,
            tabs: [
              for (final page in MainPage.values) Tab(text: page.label(l10n)),
            ],
          ),
        ),
        drawer: AppDrawer(onHome: showHome),
        floatingActionButton: index == MainPage.transactions.index
            ? const AddFab()
            : null,
        body: TabBarView(
          controller: tabs,
          children: [for (final child in children) _KeepAlive(child)],
        ),
      ),
    );
  }
}

/// Keeps a branch alive while it is swiped out of view.
class _KeepAlive extends HookWidget {
  const _KeepAlive(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    useAutomaticKeepAlive();
    return child;
  }
}
